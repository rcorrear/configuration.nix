(ns configuration-nix.graphify-test
  (:require [babashka.fs :as fs]
            [cheshire.core :as json]
            [clojure.test :refer [deftest is]]
            [configuration-nix.graphify.build :as build]
            [configuration-nix.graphify.common :as common]
            [configuration-nix.graphify.sync :as sync]))

(def head-sha "1111111111111111111111111111111111111111")

(defn temp-root
  []
  (let [root (fs/create-temp-dir {:prefix "configuration-nix-graphify-test-"})]
    (spit (str (fs/path root ".graphifyignore")) "target\n")
    (fs/create-dirs (fs/path root "packages/graphify"))
    (doseq [extractor ["clojure.py" "clojure_resolution.py" "nix.py"]]
      (spit (str (fs/path root "packages/graphify" extractor)) extractor))
    root))

(defn write-output!
  [root metadata]
  (let [output (fs/path root "graphify-out")]
    (fs/create-dirs output)
    (spit (str (fs/path output "graph.json"))
          (json/generate-string {:nodes [{:id "src_node" :source_file "modules/example.nix" :file_type "code"}]}))
    (spit (str (fs/path output "manifest.json")) "{}")
    (spit (str (fs/path output "GRAPH_REPORT.md")) "# Graph\n")
    (when metadata (common/write-metadata! output metadata))
    output))

(defn command-result
  [root dirty? calls command opts]
  (swap! calls conj {:command command :opts opts})
  (cond (= command ["git" "rev-parse" "--show-toplevel"])                  {:exit 0 :out (str root "\n") :err ""}
        (= command ["git" "rev-parse" "HEAD"])                             {:exit 0 :out (str head-sha "\n") :err ""}
        (= command ["git" "rev-parse" (str head-sha "^{tree}")])           {:exit 0 :out "tree-sha\n" :err ""}
        (= command ["graphify" "--version"])                               {:exit 0 :out "graphify 1.0\n" :err ""}
        (= command ["git" "status" "--porcelain" "--untracked-files=all"]) {:exit 0
                                                                            :out  (if dirty? " M source.clj\n" "")
                                                                            :err  ""}
        (= (take 2 command) ["graphify" "extract"])                        (do (write-output! root nil)
                                                                               {:exit 0 :out "" :err ""})
        (= (take 3 command) ["git" "remote" "get-url"])                    {:exit 1 :out "" :err "no remote"}
        :else                                                              {:exit 0 :out "" :err ""}))

(deftest graphify-build-validates-options
  (is (= {:bundle? false} (build/parse-args ["--no-bundle"])))
  (is (= "artifacts" (:artifact-dir (build/parse-args ["--artifact-dir" "artifacts"]))))
  (is (:error (build/parse-args ["--artifact-dir"])))
  (is (:error (build/parse-args ["--unknown"]))))

(deftest graphify-build-creates-validated-metadata
  (let [root  (temp-root)
        calls (atom [])]
    (try (is (= 0
                (build/run ["--no-bundle"]
                           {:now-fn (constantly "2026-01-01T00:00:00Z")
                            :env-fn (constantly nil)
                            :run-fn #(command-result root false calls %1 %2)})))
         (let [metadata (common/read-metadata (fs/path root "graphify-out"))]
           (is (= head-sha (:source_sha metadata)))
           (is (true? (:exact metadata)))
           (is (= "code-only" (:extraction metadata))))
         (is (some #(= ["graphify" "query" "NixOS Home Manager configuration" "--budget" "200"] (:command %)) @calls))
         (finally (fs/delete-tree root)))))

(deftest graphify-build-refuses-dirty-bundle-and-symlink
  (let [root  (temp-root)
        calls (atom [])]
    (try (is (= 1
                (build/run ["--artifact-dir" (str (fs/path root "artifacts"))]
                           {:env-fn (constantly nil) :run-fn #(command-result root true calls %1 %2)})))
         (when (fs/exists? (fs/path root "graphify-out")) (fs/delete-tree (fs/path root "graphify-out")))
         (fs/create-sym-link (fs/path root "graphify-out") (fs/path root "target"))
         (is
          (= 1 (build/run ["--no-bundle"] {:env-fn (constantly nil) :run-fn #(command-result root false calls %1 %2)})))
         (finally (fs/delete-tree root)))))

(deftest graphify-output-validation-rejects-missing-and-invalid-artifacts
  (let [root   (temp-root)
        output (fs/path root "graphify-out")]
    (try (fs/create-dirs output)
         (is (false? (common/valid-output? output)))
         (spit (str (fs/path output "graph.json")) "not-json")
         (spit (str (fs/path output "manifest.json")) "{}")
         (spit (str (fs/path output "GRAPH_REPORT.md")) "x")
         (is (false? (common/valid-output? output)))
         (finally (fs/delete-tree root)))))

(defn sync-runner [root dirty? calls] (fn [command opts] (command-result root dirty? calls command opts)))

(defn exact-metadata
  [root exact?]
  {:source_sha         head-sha
   :graphify_version   "graphify 1.0"
   :config_hash        (common/config-hash root "graphify 1.0")
   :exact              exact?
   :working_tree_clean exact?})

(deftest graphify-sync-reuses-clean-exact-baseline
  (let [root  (temp-root)
        calls (atom [])]
    (try (write-output! root (exact-metadata root true))
         (is (= 0 (sync/run ["--no-download"] {:run-fn (sync-runner root false calls)})))
         (is (not-any? #(#{["graphify-build" "--no-bundle"] ["graphify" "update" (str root)]} (:command %)) @calls))
         (finally (fs/delete-tree root)))))

(deftest graphify-sync-updates-dirty-current-baseline
  (let [root  (temp-root)
        calls (atom [])]
    (try (write-output! root (exact-metadata root true))
         (is (= 0 (sync/run ["--no-download"] {:now-fn (constantly "now") :run-fn (sync-runner root true calls)})))
         (is (some #(= ["graphify" "update" (str root)] (:command %)) @calls))
         (is (= "incremental" (:update_mode (common/read-metadata (fs/path root "graphify-out")))))
         (finally (fs/delete-tree root)))))

(deftest graphify-sync-falls-back-locally-and-refuses-other-commit
  (let [root  (temp-root)
        calls (atom [])]
    (try (is (= 0 (sync/run ["--no-download"] {:run-fn (sync-runner root false calls)})))
         (is (some #(= ["graphify-build" "--no-bundle"] (:command %)) @calls))
         (reset! calls [])
         (let [other  "2222222222222222222222222222222222222222"
               runner (fn [command opts]
                        (if (= command ["git" "rev-parse" "--verify" (str other "^{commit}")])
                          {:exit 1 :out "" :err ""}
                          ((sync-runner root false calls) command opts)))]
           (is (= 1 (sync/run ["--sha" other "--no-download"] {:run-fn runner}))))
         (finally (fs/delete-tree root)))))

(deftest graphify-sync-restores-other-commit-without-mutating-it
  (let [root  (temp-root)
        calls (atom [])
        other "2222222222222222222222222222222222222222"]
    (try (is (= 0 (sync/run ["--sha" other] {:restore-fn (constantly true) :run-fn (sync-runner root true calls)})))
         (is (not-any? #(#{["graphify-build" "--no-bundle"] ["graphify" "update" (str root)]} (:command %)) @calls))
         (finally (fs/delete-tree root)))))

(deftest graphify-sync-watch-runs-after-initial-sync
  (let [root  (temp-root)
        calls (atom [])]
    (try (write-output! root (exact-metadata root true))
         (is (= 0
                (sync/run ["--watch" "--no-download"]
                          {:now-fn (constantly "now") :run-fn (sync-runner root false calls)})))
         (is (some #(= ["graphify" "watch" (str root)] (:command %)) @calls))
         (is (= "watch" (:update_mode (common/read-metadata (fs/path root "graphify-out")))))
         (finally (fs/delete-tree root)))))

(deftest graphify-sync-validates-input
  (is (:error (sync/parse-args ["--sha"])))
  (is (:error (sync/parse-args ["--repo"])))
  (is (:error (sync/parse-args ["--wat"]))))
