zstyle    ':z4h:'                                        auto-update            no
zstyle    ':z4h:*'                                       channel                stable
zstyle    ':z4h:autosuggestions'                         forward-char           accept
zstyle    ':z4h:fzf-complete'                            fzf-command            my-fzf
zstyle    ':z4h:(fzf-complete|cd-down|fzf-history)'      fzf-flags              --no-exact --color=hl:14,hl+:14
zstyle    ':z4h:(fzf-complete|cd-down)'                  fzf-bindings           'tab:repeat'
zstyle    ':z4h:(fzf-complete|cd-down)'                  find-flags             -name '.git' -prune -print -o -print
zstyle    ':z4h:ssh:*'                                   ssh-command            command ssh
zstyle    ':z4h:ssh:*'                                   send-extra-files       '~/.zsh-aliases'
zstyle    ':zle:(up|down)-line-or-beginning-search'      leave-cursor           yes
zstyle    ':z4h:term-title:ssh'                          preexec                '%* | %n@%m: ${1//\%/%%}'
zstyle    ':z4h:term-title:local'                        preexec                '%* | ${1//\%/%%}'
zstyle    ':zle:up-line-or-beginning-search'             leave-cursor           true
zstyle    ':zle:down-line-or-beginning-search'           leave-cursor           true
zstyle    ':z4h:ssh:*'                                   enable                 yes
zstyle    ':z4h:ssh:planet01'                            enable                 no
zstyle    ':z4h:ssh:planet01-ha'                         enable                 no
zstyle    ':z4h:ssh:talk*'                               enable                 no
zstyle    ':z4h:ssh:corekeep'                            enable                 no
zstyle    ':z4h:ssh:keep'                                enable                 no

if ! (( P9K_SSH )); then
    zstyle ':z4h:sudo' term ''
fi

###

z4h install romkatv/archive || return
z4h init || return

####

zstyle ':completion:*' matcher-list "m:{a-z}={A-Z}" "l:|=* r:|=*"

####

fpath+=($Z4H/romkatv/archive)
autoload -Uz archive lsarchive unarchive edit-command-line

zle -N edit-command-line

my-fzf() {
    emulate -L zsh -o extended_glob
    local MATCH MBEGIN MEND
    fzf "${@:/(#m)--query=?*/$MATCH }"
}

my-ctrl-z() {
    if [[ $#BUFFER -eq 0 ]]; then
        BUFFER="fg"
        zle accept-line -w
    else
        zle push-input -w
        zle clear-screen -w
    fi
}
zle -N my-ctrl-z

toggle-sudo() {
    [[ -z "$BUFFER" ]] && zle up-history -w
    if [[ "$BUFFER" != "sudo "* ]]; then
        BUFFER="sudo $BUFFER"
        CURSOR=$(( CURSOR + 5 ))
    else
        BUFFER="${BUFFER#sudo }"
    fi
}
zle -N toggle-sudo

###

z4h bindkey z4h-backward-kill-word  Ctrl+Backspace
z4h bindkey z4h-backward-kill-zword Ctrl+Alt+Backspace
z4h bindkey z4h-kill-zword          Ctrl+Alt+Delete

z4h bindkey z4h-forward-zword       Ctrl+Alt+Right
z4h bindkey z4h-backward-zword      Ctrl+Alt+Left

z4h bindkey z4h-cd-back             Alt+H
z4h bindkey z4h-cd-forward          Alt+L
z4h bindkey z4h-cd-up               Alt+K
z4h bindkey z4h-cd-down             Alt+J

z4h bindkey toggle-sudo             Alt+S
z4h bindkey my-ctrl-z               Ctrl+Z
z4h bindkey edit-command-line       Alt+E

###

setopt GLOB_DOTS

###

[ -z "$EDITOR" ] && export EDITOR='vim'
[ -z "$VISUAL" ] && export VISUAL='vim'

export DIRENV_LOG_FORMAT=
export FZF_DEFAULT_OPTS="--reverse --multi"
export SYSTEMD_LESS=FRXMK

###

command -v direnv &> /dev/null && eval "$(direnv hook zsh)"

###

z4h source -- /etc/bash_completion.d/azure-cli
z4h source -- /usr/share/nnn/quitcd/quitcd.bash_zsh
z4h source -- $ZDOTDIR/.zsh-aliases
z4h source -- $ZDOTDIR/.zshrc-private
z4h source -- $ZDOTDIR/zsh-wakatime.plugin.zsh