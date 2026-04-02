# If not running interactively, don't do anything
[[ $- != *i* ]] && return

source ~/.config/bash/envs
source ~/.config/bash/shell
source ~/.config/bash/aliases
for f in ~/.config/bash/functions/*; do [[ -f "$f" ]] && source "$f"; done
source ~/.config/bash/init

[[ $- == *i* ]] && bind -f ~/.inputrc
