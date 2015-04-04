{:user
 {:plugins [[lein-ritz "0.6.0"]
            [lein-pprint "1.1.1"]
            [lein-clojars "0.9.1"]
            [lein-midje "3.0.1"]
            [lein-marginalia "0.7.1"]
            [cider/cider-nrepl "0.9.0-SNAPSHOT"]
            [refactor-nrepl "1.0.1"]]
  :aliases {"slamhound" ["run" "-m" "slam.hound"]}
  :dependencies [[org.clojure/tools.nrepl "0.2.10"]
                 [slamhound "1.5.5"]]}}
