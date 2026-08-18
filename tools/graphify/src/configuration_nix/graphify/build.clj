(ns configuration-nix.graphify.build
  (:require [babashka.fs :as fs]
            [clojure.string :as str]
            [configuration-nix.graphify.common :as common]
            [configuration-nix.graphify.process :as process]))

(def usage
  "Usage: graphify-build [--artifact-dir DIR] [--no-bundle]

Build a clean, AST-only Graphify graph for the current checkout. No LLM
credentials are used. When --artifact-dir is supplied, write an exact-SHA
tar.zst bundle there.")

(defn parse-args
  [args]
  (loop [remaining args
         opts      {:bundle? true}]
    (if-let [arg (first remaining)]
      (case arg
        ("-h" "--help")  (recur (rest remaining) (assoc opts :help? true))
        "--no-bundle"    (recur (rest remaining) (assoc opts :bundle? false))
        "--artifact-dir" (if-let [value (second remaining)]
                           (recur (nnext remaining) (assoc opts :artifact-dir value))
                           {:error "--artifact-dir requires a directory"})
        {:error (str "Unknown argument: " arg)})
      opts)))

(defn validate-graph!
  [root output-dir run-fn]
  (doseq [required common/required-artifacts]
    (when-not (common/nonempty-file? (fs/path output-dir required))
      (throw (ex-info (str "Graphify did not produce required output: " required) {:artifact required}))))
  (let [graph  (common/parse-json-file (fs/path output-dir "graph.json"))
        _ (common/parse-json-file (fs/path output-dir "manifest.json"))
        nodes  (:nodes graph)
        prefix (-> (str root)
                   (str/replace #"[^A-Za-z0-9]+" "_")
                   str/lower-case
                   (str/replace #"^_" ""))]
    (when-not (some #(and (str/ends-with? (or (:source_file %) "") ".nix") (= "code" (:file_type %))) nodes)
      (throw (ex-info "Graphify graph contains no Nix code nodes." {})))
    (when (some #(str/starts-with? (str (:id %)) prefix) nodes)
      (throw (ex-info "Graphify graph contains checkout-absolute node IDs." {:prefix prefix}))))
  (common/ensure-success! (run-fn ["graphify" "query" "NixOS Home Manager configuration" "--budget" "200"] {:dir root})
                          ["graphify" "query"]))

(defn build!
  [{:keys [artifact-dir bundle?]}
   {:keys [env-fn now-fn run-fn] :or {env-fn #(System/getenv %) now-fn common/utc-now run-fn process/run}}]
  (let [root          (common/command-output run-fn "." ["git" "rev-parse" "--show-toplevel"])
        output-dir    (fs/path root "graphify-out")
        source-sha    (or (env-fn "GRAPHIFY_SOURCE_SHA") (common/command-output run-fn root ["git" "rev-parse" "HEAD"]))
        tree-sha      (common/command-output run-fn root ["git" "rev-parse" (str source-sha "^{tree}")])
        version       (common/command-output run-fn root ["graphify" "--version"])
        status        (common/command-output run-fn root ["git" "status" "--porcelain" "--untracked-files=all"])
        clean?        (str/blank? status)
        configuration (common/config-hash root version)]
    (when (fs/sym-link? output-dir)
      (throw (ex-info (str "Refusing to replace symlinked output directory: " output-dir) {})))
    (when (fs/exists? output-dir) (fs/delete-tree output-dir))
    (common/ensure-success! (run-fn ["graphify" "extract" root "--code-only"]
                                    {:dir root :extra-env {"PYTHONHASHSEED" "0"}})
                            ["graphify" "extract"])
    (common/ensure-success! (run-fn ["graphify" "cluster-only" root "--no-viz" "--no-label"] {:dir root})
                            ["graphify" "cluster-only"])
    (validate-graph! root output-dir run-fn)
    (common/write-metadata! output-dir
                            {:schema_version     1
                             :source_sha         source-sha
                             :tree_sha           tree-sha
                             :graphify_version   version
                             :config_hash        configuration
                             :extraction         "code-only"
                             :llm_used           false
                             :exact              clean?
                             :working_tree_clean clean?
                             :generated_at       (now-fn)})
    (if (and bundle? artifact-dir)
      (do (when-not clean? (throw (ex-info "Refusing to publish an exact-SHA artifact from a dirty working tree." {})))
          (fs/create-dirs artifact-dir)
          (let [artifact (str (fs/path artifact-dir (str "graphify-" source-sha ".tar.zst")))
                command  ["tar" "--zstd" "-cf" artifact "-C" root "graphify-out"]]
            (common/ensure-success! (run-fn command {:dir root}) command)
            (println artifact)
            artifact))
      (do (println (str "Graphify baseline built at " output-dir)) (str output-dir)))))

(defn run
  ([args] (run args {}))
  ([args effects]
   (let [{:keys [error help?] :as opts} (parse-args args)]
     (cond error (do (binding [*out* *err*]
                       (println error)
                       (println usage))
                     2)
           help? (do (println usage) 0)
           :else (try (build! opts effects)
                      0
                      (catch Exception e (binding [*out* *err*] (println (ex-message e))) 1))))))

(defn -main [& args] (System/exit (run args)))

