-- REX Nvim Navigator
require("rex-navigator").setup()

-- TMUX Bindings
rex.bind("ctrl+s>c", "client.tab.new")
rex.bind("ctrl+s>n", "client.tab.next")
rex.bind("ctrl+s>p", "client.tab.previous")
-- % and " on a US layout
rex.bind("ctrl+s>shift+\\", "pane.split", { direction = "right" })
rex.bind("ctrl+s>-", "pane.split", { direction = "down" })
rex.bind("ctrl+s>z", "pane.zoom")
rex.bind("ctrl+s>x", "pane.close")

-- Press Ctrl+S twice to send one to the terminal
rex.bind("ctrl+s>ctrl+s", "pane.send_key", { key = "ctrl+s" })
