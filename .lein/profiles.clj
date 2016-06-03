{:user
 {:exclusions [cider/cider-nrepl]
  :plugins [[lein-pprint "1.1.1"]
            [lein-ancient "0.6.8" :exclusions [org.clojure/clojure]]]
  :aliases {"slamhound" ["run" "-m" "slam.hound"]}
  :dependencies [[radicalzephyr/repl-utils "0.2.0"]
                 [org.clojure/tools.trace "0.7.9"]
                 [com.gfredericks/debug-repl "0.0.7"]
                 [slamhound "1.5.5"]]
  :repl-options {:init (do
                         (require '[radicalzephyr.repl-utils
                                    :refer :all])
                         (set! *print-length* 100))
                 :nrepl-middleware
                 [com.gfredericks.debug-repl/wrap-debug-repl]}
  :repositories {"clojars" {:creds :gpg}}}}
