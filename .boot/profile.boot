(require 'boot.repl)
(swap! boot.repl/*default-dependencies*
       concat '[[jeluard/boot-notify "0.2.0"]
                [radicalzephyr/repl-utils "0.2.0"]])

(swap! boot.repl/*default-middleware*
       concat '[cider.nrepl/cider-middleware
                refactor-nrepl.middleware/wrap-refactor])
