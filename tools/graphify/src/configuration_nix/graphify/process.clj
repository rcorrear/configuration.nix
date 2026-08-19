(ns configuration-nix.graphify.process
  (:require [babashka.process :as process]))

(defn run
  ([command] (run command {}))
  ([command opts]
   (let [{:keys [exit out err]} @(process/process command (merge {:out :string :err :string :continue true} opts))]
     {:exit exit :out out :err err})))

