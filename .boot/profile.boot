(require 'boot.repl)
(swap! boot.repl/*default-dependencies*
       concat '[[radicalzephyr/repl-utils "0.2.0"]])

