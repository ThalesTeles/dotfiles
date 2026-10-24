#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto --group-directories-first'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
alias mwall='matugen image'

export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
*":$PNPM_HOME/bin:"*) ;;
*) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
export PATH=~/.npm-global/bin:$PATH

# Unity CLI
case ":${PATH}:" in *:"$HOME/.local/bin":*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
