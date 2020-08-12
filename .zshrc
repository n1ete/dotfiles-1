zstyle    ':z4h:'                                        auto-update            no
zstyle    ':z4h:*'                                       channel                stable
zstyle    ':z4h:'                                        cd-key                 alt
zstyle    ':z4h:autosuggestions'                         forward-char           accept
zstyle    ':z4h:ssh:*'                                   ssh-command            command ssh
zstyle    ':z4h:ssh:*'                                   send-extra-files       '~/.zsh-aliases'
zstyle -e ':z4h:ssh:*'                                   retrieve-history       'reply=($ZDOTDIR/.zsh_history.${(%):-%m}:$z4h_ssh_host)'
zstyle    ':fzf-tab:*'                                   continuous-trigger     tab
zstyle    ':zle:(up|down)-line-or-beginning-search'      leave-cursor           no
zstyle    ':z4h:term-title:ssh'                          preexec                '%* | %n@%m: ${1//\%/%%}'
zstyle    ':z4h:term-title:local'                        preexec                '%* | ${1//\%/%%}'
zstyle    ':z4h:ssh:jukebot'     passthrough             yes
zstyle    ':z4h:ssh:planet01'     passthrough            yes
zstyle    ':z4h:ssh:talk'     passthrough                yes
zstyle    ':z4h:ssh:probe'     passthrough               yes
zstyle    ':z4h:ssh:holo01'     passthrough              yes
zstyle    ':z4h:ssh:bruno'     passthrough               yes
zstyle    ':z4h:ssh:vbox'     passthrough                yes
zstyle    ':z4h:ssh:corekeep'     passthrough            yes
zstyle    ':z4h:ssh:keep'     passthrough                yes
zstyle    ':z4h:ssh:mufu'     passthrough                yes

z4h install romkatv/archive || return

z4h init || return

fpath+=($Z4H/romkatv/archive)
autoload -Uz archive lsarchive unarchive edit-command-line

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
bindkey '^Z' my-ctrl-z

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
bindkey '^[s' toggle-sudo

zle -N edit-command-line
bindkey '^V^V' edit-command-line

bindkey '^H'      z4h-backward-kill-word
bindkey '^[[1;7C' z4h-forward-zword
bindkey '^[[1;7D' z4h-backward-zword
bindkey '^[[3;7~' z4h-kill-zword
bindkey '^[^H'    z4h-backward-kill-zword

command -v direnv &> /dev/null && eval "$(direnv hook zsh)"

setopt GLOB_DOTS

z4h source -c /etc/bash_completion.d/azure-cli
z4h source -c /usr/share/LS_COLORS/dircolors.sh
z4h source -c /usr/share/nnn/quitcd/quitcd.bash_zsh
z4h source -c ~/.zsh-aliases
z4h source -c ~/.zshrc-private

[ -f ~/.dotfiles/z4h.patch ] && patch -Np1 -i ~/.dotfiles/z4h.patch -r /dev/null -d $Z4H/zsh4humans/ > /dev/null

return 0
