{:user
 {:plugins [[lein-ritz "0.7.0"]
            [lein-pprint "1.1.1"]
            [lein-clojars "0.9.1"]
            [lein-midje "3.1.3"]
            [lein-checkall "0.1.1"]
            [lein-marginalia "0.7.1"]
            [cider/cider-nrepl "0.10.0-SNAPSHOT"]
            [refactor-nrepl "1.2.0-SNAPSHOT"]]
  :aliases {"slamhound" ["run" "-m" "slam.hound"]}
  :dependencies [[radicalzephyr/repl-utils "0.2.0"]
                 [org.clojure/tools.namespace "0.2.10"]
                 [org.clojure/tools.nrepl "0.2.10"]
                 [slamhound "1.5.5"]]
  :repl-options {:init (require '[radicalzephyr.repl-utils
                                  :refer :all])}
  :repositories [["clojars" {:creds :gpg}]]}}
