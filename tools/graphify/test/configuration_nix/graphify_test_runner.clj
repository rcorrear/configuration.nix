(ns configuration-nix.graphify-test-runner
  (:require [clojure.test :as test]))

(def test-namespaces '[configuration-nix.graphify-test])

(defn run
  []
  (doseq [test-ns test-namespaces] (require test-ns))
  (let [{:keys [fail error]} (apply test/run-tests test-namespaces)]
    (when-not (zero? (+ fail error))
      (throw (ex-info "Graphify lifecycle tests failed." {:fail fail :error error})))
    :ok))
