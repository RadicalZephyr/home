(require 'boot.repl)

(swap! boot.repl/*default-dependencies*
       concat '[[radicalzephyr/repl-utils "0.2.0" :exclusions [org.clojure/clojure]]])

(set-env! :dependencies '[[boot-deps "0.1.6" :exclusions [org.clojure/clojure]]
                          [radicalzephyr/bootlaces     "0.1.15-SNAPSHOT" :scope "test"]
                          [org.clojure/tools.trace "0.7.9" :scope "test" :exclusions [org.clojure/clojure]]
                          [samestep/boot-refresh "0.1.0" :scope "test" :exclusions [org.clojure/clojure]]])

(require '[radicalzephyr.bootlaces :refer :all]
         '[boot-deps :refer [ancient latest]]
         '[samestep.boot-refresh :refer [refresh]])
