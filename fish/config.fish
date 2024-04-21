# FISH Shell Configuration
# by Jason Shanks
# Date created: 2020-04-18
# Date updated: 2024-03-01

# Set Fish greeting
set -U fish_greeting "Go 🐟"
#function fish_greeting
#    fortune
#end

set -x R_VERIFY_TASK false
set -x R_AUTO_TIMEOUT 5
set -x R_DEBUG false
set -x R_QUIET false

# Set my editor and git editor
set -x EDITOR nvim
set -x GIT_EDITOR nvim
# set -x EDITOR "$HOME/scripts/editor.sh"
# set -x GIT_EDITOR "$HOME/scripts/editor.sh"
set -x EDITSCRIPT_EDITOR "$HOME/scripts/editor.sh"
set -x EDITSCRIPT_PATH "~/scripts:~/scripts/fish:~/.config/fish:~/.config/fish/functions:~/bin:~/.bash_it/custom:~/.bash_it/**/enabled:~/.*"
set -x EDITSCRIPT_TYPES "rb,sh,py,bash,fish,,"

# na
set -x NA_TODO_EXT taskpaper
set -x NA_NEXT_TAG "@na"
set -x NA_DONE_TAG "@done"
set -x NA_MAX_DEPTH 2
set -x NA_AUTO_LIST_FOR_DIR 1
set -x NA_AUTO_LIST_IS_RECURSIVE 0

# NVM
function __check_rvm --on-variable PWD --description 'Do nvm s
tuff'
    status --is-command-substitution; and return

    if test -f .nvmrc; and test -r .nvmrc
        nvm use
    else
    end
end

switch (uname)
    case Darwin
        source (dirname (status --current-filename))/config-osx.fish
    case Linux
        source (dirname (status --current-filename))/config-linux.fish
    case '*'
        source (dirname (status --current-filename))/config-windows.fish
end

set LOCAL_CONFIG (dirname (status --current-filename))/config-local.fish
if test -f $LOCAL_CONFIG
    source $LOCAL_CONFIG
end

# Source dependencies
#source ~/.config/fish/custom.fish
set -g fish_user_paths /opt/homebrew/bin/libxml2/bin $fish_user_paths
clear
source ~/.config/.aliases
source ~/.config/.functions

### Fish syntax highlighting
set -g fish_color_autosuggestion 555 brblack
set -g fish_color_cancel -r
set -g fish_color_command --bold

### Fish keybindings
# fish_vi_key_bindings

# fzf key bindings
fzf --fish | source

# Abbreviations
abbr -a -- - prevd
abbr -a -- = nextd

# CUSTOM PATHS
set -x PATH $PATH /Users/jason/.composer/vendor/bin/
set -g fish_user_paths /opt/homebrew/bin $fish_user_paths
