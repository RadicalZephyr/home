(require 'boot.repl)
(swap! boot.repl/*default-dependencies*
       concat '[[radicalzephyr/repl-utils "0.2.0"]])

(set-env! :dependencies '[[boot-deps "0.1.6" ]
                          [org.clojure/tools.trace "0.7.9" :exclusions [org.clojure/clojure]]
                          [samestep/boot-refresh "0.1.0" :scope "test"]])

(require '[boot-deps :refer [ancient latest]]
         '[samestep.boot-refresh :refer [refresh]])
