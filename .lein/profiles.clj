{:user
 {:exclusions [cider/cider-nrepl]
  :plugins [[lein-pprint "1.1.1"]
            [lein-midje "3.2"]
            [lein-marginalia "0.8.0"]
            [cider/cider-nrepl "0.10.0-SNAPSHOT"]
            [refactor-nrepl "2.0.0-SNAPSHOT"]]
  :aliases {"slamhound" ["run" "-m" "slam.hound"]}
  :dependencies [[radicalzephyr/repl-utils "0.2.0"]
                 [org.clojure/tools.namespace "0.2.11"]
                 [org.clojure/tools.nrepl "0.2.12"]
                 [com.gfredericks/debug-repl "0.0.7"]
                 [slamhound "1.5.5"]]
  :repl-options {:init (require '[radicalzephyr.repl-utils
                                  :refer :all])
                 :nrepl-middleware
                 [com.gfredericks.debug-repl/wrap-debug-repl]}
  :repositories [["clojars" {:creds :gpg}]]}}
