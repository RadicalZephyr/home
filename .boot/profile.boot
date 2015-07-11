(require 'boot.repl)
(swap! boot.repl/*default-dependencies*
       concat '[[cider/cider-nrepl "0.9.0-SNAPSHOT"]
                [refactor-nrepl "1.1.0-SNAPSHOT"]
                [jeluard/boot-notify "0.1.2"]
                [radicalzephyr/repl-utils "0.2.0"]])

(swap! boot.repl/*default-middleware*
       concat '[cider.nrepl/cider-middleware
                refactor-nrepl.middleware/wrap-refactor])
