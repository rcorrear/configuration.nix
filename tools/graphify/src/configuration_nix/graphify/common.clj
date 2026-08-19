(ns configuration-nix.graphify.common
  (:require [babashka.fs :as fs]
            [cheshire.core :as json]
            [clojure.java.io :as io]
            [clojure.string :as str])
  (:import [java.security MessageDigest]
           [java.time Instant]))

(def required-artifacts ["graph.json" "manifest.json" "GRAPH_REPORT.md"])

(defn sha256
  [value]
  (let [digest (.digest (MessageDigest/getInstance "SHA-256") (.getBytes (str value) "UTF-8"))]
    (apply str (map #(format "%02x" (bit-and % 0xff)) digest))))

(defn config-hash
  [root graphify-version]
  (let [extractors ["packages/graphify/clojure.py"
                    "packages/graphify/clojure_resolution.py"
                    "packages/graphify/nix.py"]]
    (sha256
     (str graphify-version
          "\nextract --code-only\n"
          (slurp (str (fs/path root ".graphifyignore")))
          (apply str
                 (for [extractor (conj extractors "packages/graphify/default.nix")]
                   (str "\n" extractor "\n" (slurp (str (fs/path root extractor))))))))))

(defn nonempty-file? [path] (and (fs/regular-file? path) (pos? (fs/size path))))

(defn parse-json-file [path] (json/parse-string (slurp (str path)) true))

(defn valid-output?
  [output-dir]
  (try (and (every? #(nonempty-file? (fs/path output-dir %)) required-artifacts)
            (map? (parse-json-file (fs/path output-dir "graph.json")))
            (map? (parse-json-file (fs/path output-dir "manifest.json"))))
       (catch Exception _ false)))

(defn read-metadata
  [output-dir]
  (try (parse-json-file (fs/path output-dir "build-metadata.json")) (catch Exception _ nil)))

(defn write-metadata!
  [output-dir metadata]
  (spit (str (fs/path output-dir "build-metadata.json")) (str (json/generate-string metadata {:pretty true}) "\n")))

(defn utc-now [] (str (Instant/now)))

(defn ensure-success!
  [{:keys [exit out err]} command]
  (when-not (zero? exit)
    (throw (ex-info (format "Command failed (%s): %s" exit (str/join " " command))
                    {:command command :exit exit :out out :err err}))))

(defn command-output
  [run-fn root command]
  (let [result (run-fn command {:dir root})]
    (ensure-success! result command)
    (str/trim (or (:out result) ""))))

(defn repository-from-remote
  [remote]
  (some-> remote
          str/trim
          (str/replace #"^(git@|ssh://git@)github\.com[:/]" "")
          (str/replace #"^https://github\.com/" "")
          (str/replace #"\.git$" "")
          not-empty))

(defn safe-replace-directory!
  [target staged]
  (when (fs/sym-link? target)
    (throw (ex-info (str "Refusing to replace symlinked output directory: " target) {:target (str target)})))
  (when (fs/exists? target) (fs/delete-tree target))
  (fs/move staged target))

(defn executable-file? [path] (let [file (io/file (str path))] (and (.isFile file) (.canExecute file))))
