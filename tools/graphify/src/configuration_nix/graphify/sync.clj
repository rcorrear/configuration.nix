(ns configuration-nix.graphify.sync
  (:require [babashka.fs :as fs]
            [clojure.string :as str]
            [configuration-nix.graphify.common :as common]
            [configuration-nix.graphify.process :as process]))

(def usage
  "Usage: graphify-sync [--sha SHA] [--repo OWNER/REPO] [--no-download] [--watch]

Restore Graphify output built for the exact source SHA. For a dirty working
tree, update the commit baseline incrementally. Fall back to a local build only
for the checked-out commit.")

(defn parse-args
  [args]
  (loop [remaining args
         opts      {:download? true :watch? false}]
    (if-let [arg (first remaining)]
      (case arg
        ("-h" "--help") (recur (rest remaining) (assoc opts :help? true))
        "--no-download" (recur (rest remaining) (assoc opts :download? false))
        "--watch"       (recur (rest remaining) (assoc opts :watch? true))
        "--sha"         (if-let [value (second remaining)]
                          (recur (nnext remaining) (assoc opts :sha value))
                          {:error "--sha requires a commit SHA"})
        "--repo"        (if-let [value (second remaining)]
                          (recur (nnext remaining) (assoc opts :repository value))
                          {:error "--repo requires OWNER/REPO"})
        {:error (str "Unknown argument: " arg)})
      opts)))

(defn baseline-current?
  [output-dir target-sha version configuration]
  (and (common/valid-output? output-dir)
       (let [metadata (common/read-metadata output-dir)]
         (and (= target-sha (:source_sha metadata))
              (= version (:graphify_version metadata))
              (= configuration (:config_hash metadata))))))

(defn baseline-exact?
  [output-dir target-sha version configuration]
  (and (baseline-current? output-dir target-sha version configuration)
       (true? (:exact (common/read-metadata output-dir)))))

(defn install-restored-output!
  [output-dir staged target-sha version configuration]
  (let [metadata (common/read-metadata staged)]
    (when-not (and (common/valid-output? staged)
                   (true? (:exact metadata))
                   (= target-sha (:source_sha metadata))
                   (= version (:graphify_version metadata))
                   (= configuration (:config_hash metadata)))
      (throw (ex-info "Downloaded Graphify artifact failed validation." {})))
    (common/safe-replace-directory! output-dir staged)))

(defn mark-working-copy!
  [output-dir mode now-fn]
  (let [metadata (common/read-metadata output-dir)]
    (when-not metadata (throw (ex-info "Missing Graphify build metadata." {})))
    (common/write-metadata!
     output-dir
     (assoc metadata :exact false :working_tree_clean false :update_mode mode :updated_at (now-fn)))))

(defn resolve-target-sha
  [root requested head-sha run-fn]
  (if-not requested
    head-sha
    (let [result (run-fn ["git" "rev-parse" "--verify" (str requested "^{commit}")] {:dir root})]
      (cond (zero? (:exit result)) (str/trim (:out result))
            (re-matches #"[0-9a-fA-F]{40}" requested) (str/lower-case requested)
            :else (throw (ex-info (str "Requested SHA is neither a local commit nor a full commit ID: " requested)
                                  {}))))))

(defn restore-artifact!
  [root output-dir target-sha repository version configuration run-fn]
  (when (and repository (zero? (:exit (run-fn ["gh" "auth" "status"] {:dir root}))))
    (let [artifact-name (str "graphify-" target-sha)
          query-result
          (run-fn
           ["gh" "api" (str "repos/" repository "/actions/artifacts?name=" artifact-name "&per_page=100") "--jq"
            "[.artifacts[] | select(.expired == false)] | sort_by(.created_at) | last | .archive_download_url // empty"]
           {:dir root})
          artifact-url (str/trim (or (:out query-result) ""))]
      (when (and (zero? (:exit query-result)) (seq artifact-url))
        (let [temp-dir (fs/create-temp-dir {:prefix "configuration-nix-graphify-sync-"})
              archive  (fs/path temp-dir "artifact.zip")
              unpacked (fs/path temp-dir "unpacked")
              bundle   (fs/path temp-dir (str artifact-name ".tar.zst"))]
          (try (fs/create-dirs unpacked)
               (common/ensure-success! (run-fn ["gh" "api" artifact-url] {:dir root :out (str archive)}) ["gh" "api"])
               (common/ensure-success! (run-fn ["unzip" "-q" (str archive) "-d" (str temp-dir)] {:dir root}) ["unzip"])
               (when-not (common/nonempty-file? bundle) (throw (ex-info "Downloaded Graphify bundle is missing." {})))
               (common/ensure-success! (run-fn ["tar" "--zstd" "-xf" (str bundle) "-C" (str unpacked)] {:dir root})
                                       ["tar"])
               (let [staged (fs/path unpacked "graphify-out")]
                 (install-restored-output! output-dir staged target-sha version configuration)
                 (println (str "Restored Graphify artifact for " target-sha))
                 true)
               (catch Exception _ false)
               (finally (when (fs/exists? temp-dir) (fs/delete-tree temp-dir)))))))))

(defn sync!
  [{:keys [download? repository sha watch?]}
   {:keys [env-fn now-fn restore-fn run-fn] :or {env-fn #(System/getenv %) now-fn common/utc-now run-fn process/run}}]
  (let [root          (common/command-output run-fn "." ["git" "rev-parse" "--show-toplevel"])
        output-dir    (fs/path root "graphify-out")
        head-sha      (common/command-output run-fn root ["git" "rev-parse" "HEAD"])
        target-sha    (resolve-target-sha root sha head-sha run-fn)
        clean?        (str/blank?
                       (common/command-output run-fn root ["git" "status" "--porcelain" "--untracked-files=all"]))
        version       (common/command-output run-fn root ["graphify" "--version"])
        configuration (common/config-hash root version)
        repository    (or repository
                          (env-fn "GRAPHIFY_GITHUB_REPOSITORY")
                          (let [result (run-fn ["git" "remote" "get-url" "origin"] {:dir root})]
                            (when (zero? (:exit result)) (common/repository-from-remote (:out result)))))
        restore-fn    (or restore-fn
                          #(restore-artifact! root output-dir target-sha repository version configuration run-fn))
        restore       #(and download? (restore-fn))
        local-build   #(common/ensure-success! (run-fn ["graphify-build" "--no-bundle"]
                                                       {:dir root :extra-env {"GRAPHIFY_SOURCE_SHA" target-sha}})
                                               ["graphify-build"])
        update        #(do (common/ensure-success! (run-fn ["graphify" "update" root] {:dir root})
                                                   ["graphify" "update"])
                           (mark-working-copy! output-dir "incremental" now-fn))]
    (if (not= target-sha head-sha)
      (cond watch?    (throw (ex-info "--watch requires the checked-out commit." {}))
            (restore) :restored
            :else     (throw (ex-info (format "Cannot rebuild Graphify for %s from checkout %s." target-sha head-sha)
                                      {})))
      (do (if clean?
            (when-not (baseline-exact? output-dir target-sha version configuration) (when-not (restore) (local-build)))
            (if (baseline-current? output-dir target-sha version configuration)
              (update)
              (if (restore) (update) (local-build))))
          (when watch?
            (mark-working-copy! output-dir "watch" now-fn)
            (common/ensure-success! (run-fn ["graphify" "watch" root] {:dir root :out :inherit :err :inherit})
                                    ["graphify" "watch"]))
          :ok))))

(defn run
  ([args] (run args {}))
  ([args effects]
   (let [{:keys [error help?] :as opts} (parse-args args)]
     (cond error (do (binding [*out* *err*]
                       (println error)
                       (println usage))
                     2)
           help? (do (println usage) 0)
           :else (try (sync! opts effects) 0 (catch Exception e (binding [*out* *err*] (println (ex-message e))) 1))))))

(defn -main [& args] (System/exit (run args)))
