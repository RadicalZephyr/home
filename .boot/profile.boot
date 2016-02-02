(require 'boot.repl)
(swap! boot.repl/*default-dependencies*
       concat '[[cider/cider-nrepl "0.11.0-SNAPSHOT"]
                [refactor-nrepl "2.0.0-SNAPSHOT"]
                [jeluard/boot-notify "0.2.0"]
                [radicalzephyr/repl-utils "0.2.0"]])

(swap! boot.repl/*default-middleware*
       concat '[cider.nrepl/cider-middleware
                refactor-nrepl.middleware/wrap-refactor])
