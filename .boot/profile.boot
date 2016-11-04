(require 'boot.repl)
(swap! boot.repl/*default-dependencies*
       concat '[[radicalzephyr/repl-utils "0.2.0"]])

(set-env! :dependencies '[[boot-deps "0.1.6" ]
                          [org.clojure/tools.trace "0.7.9" :exclusions [org.clojure/clojure]]])

(require '[boot-deps :refer [ancient latest]])
