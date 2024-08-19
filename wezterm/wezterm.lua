-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Appearance
config.window_decorations = "RESIZE"
config.color_scheme = "Tokyo Night"
config.enable_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true

-- Fonts
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 20

-- Keybindings
config.keys = {
	-- TODO: Disable vim navigation keys that conflict with TMUX/VIM navigation. Fails because Wezterm doesn't support TMUX
	{ key = "h", mods = "CTRL", action = wezterm.action.DisableDefaultAssignment },
	{ key = "j", mods = "CTRL", action = wezterm.action.DisableDefaultAssignment },
	{ key = "k", mods = "CTRL", action = wezterm.action.DisableDefaultAssignment },
	{ key = "l", mods = "CTRL", action = wezterm.action.DisableDefaultAssignment },
}
-- and finally, return the configuration to wezterm
return config
