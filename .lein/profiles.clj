{:user
 {:exclusions [cider/cider-nrepl]
  :plugins [[lein-pprint "1.3.2"]
            [lein-ancient "1.0.0-RC4-SNAPSHOT" :exclusions [org.clojure/clojure]]]
  :aliases {"slamhound" ["run" "-m" "slam.hound"]}
  :dependencies [[radicalzephyr/repl-utils "0.2.0"]
                 [org.clojure/tools.trace "0.7.9"]
                 [com.gfredericks/debug-repl "0.0.8"]
                 [slamhound "1.5.5"]]
  :repl-options {:init (do
                         (require '[radicalzephyr.repl-utils
                                    :refer :all])
                         (set! *print-length* 100))
                 :nrepl-middleware
                 [com.gfredericks.debug-repl/wrap-debug-repl]}}}
