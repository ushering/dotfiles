#!/bin/zsh

# Aliases specific to zsh

alias zsrc="source ~/.zshrc"
alias ex=extract_archive

# global aliases, dont have to be at the beginning of a line
alias -g H='| head'
alias -g T='| tail'
alias -g G='| grep'
alias -g L="| less"
alias -g M="| most"
alias -g LL="2>&1 | less"
alias -g CA="2>&1 | cat -A"
alias -g NE="2> /dev/null"
alias -g NUL="> /dev/null 2>&1"


alias ...='cd ../../'
alias ....='cd ../../../'
alias .....="echo 'use: up N;'"

if [[ -r /proc/mdstat ]]; then
  alias mdstat='cat /proc/mdstat'
fi

# generate alias named "$KERNELVERSION-reboot" so you can use boot with kexec:
if [[ -x /sbin/kexec ]] && [[ -r /proc/cmdline ]] ; then
  alias "$(uname -r)-reboot"="kexec -l --initrd=/boot/initrd.img-"$(uname -r)" --command-line=\"$(cat /proc/cmdline)\" /boot/vmlinuz-"$(uname -r)""
fi

# use /var/log/syslog iff present, fallback to journalctl otherwise
if [ -e /var/log/syslog ] ; then
  # Take a look at the syslog: \$PAGER /var/log/syslog || journalctl
  salias llog="$PAGER /var/log/syslog"     # take a look at the syslog
  # Take a look at the syslog: tail -f /var/log/syslog || journalctl
  salias tlog="tail -f /var/log/syslog"    # follow the syslog
elif external-command-exists journalctl ; then
  salias llog="journalctl"
  salias tlog="journalctl -f"
fi


# we don't want to quote/espace URLs on our own...
# if autoload -U url-quote-magic ; then
#    zle -N self-insert url-quote-magic
#    zstyle ':url-quote-magic:*' url-metas '*?[]^()~#{}='
# else
#    print 'Notice: no url-quote-magic available :('
# fi
alias url-quote='autoload -U url-quote-magic; \
    zle -N self-insert url-quote-magic'

# do we have GNU ls with color-support?
if [[ "$TERM" != dumb ]]; then
  #a1# List files with colors (ls \ldots)
  alias ls="command ls ${ls_options:+${ls_options[*]}}"
  #a1# List all files, with colors (ls -la \ldots)
  alias la="command ls -la ${ls_options:+${ls_options[*]}}"
  #a1# List files with long colored list, without dotfiles (ls -l \ldots)
  alias ll="command ls -l ${ls_options:+${ls_options[*]}}"
  #a1# List files with long colored list, human readable sizes (ls -hAl \ldots)
  alias lh="command ls -hAl ${ls_options:+${ls_options[*]}}"
  #a1# List files with long colored list, append qualifier to filenames (ls -l \ldots)\\&\quad(\kbd{/} for directories, \kbd{@} for symlinks ...)
  alias l="command ls -l ${ls_options:+${ls_options[*]}}"
else
  alias la='command ls -la'
  alias ll='command ls -l'
  alias lh='command ls -hAl'
  alias l='command ls -l'
fi
# general
# Execute du -sch
alias da='du -sch'
alias g='git'
alias gRl='git remote --verbose'
alias rz='reload-zshrc'
alias e='emacsclient --no-wait'
alias rmcdir='cd ..; rmdir $OLDPWD || cd $OLDPWD'
alias sll='symbolic-link-detail'

# listing stuff
# Execute ls -lSrah
alias dir="command ls -lSrah"
# Only show dot-directories
alias lad='command ls -d .*(/)'
# Only show dot-files
alias lsa='command ls -a .*(.)'
# Only files with setgid/setuid/sticky flag
alias lss='command ls -l *(s,S,t)'
# Only show symlinks
alias lsl='command ls -l *(@)'
# Display only executables
alias lsx='command ls -l *(*)'
# Display world-{readable,writable,executable} files
alias lsw='command ls -ld *(R,W,X.^ND/)'
# Display the ten biggest files
alias lsbig="command ls -flh *(.OL[1,10])"
# Only show directories
alias lsd='command ls -d *(/)'
# Only show empty directories
alias lse='command ls -d *(/^F)'
# Display the ten newest files
alias lsnew="command ls -rtlh *(D.om[1,10])"
# Display the ten oldest files
alias lsold="command ls -rtlh *(D.Om[1,10])"
# Display the ten smallest files
alias lssmall="command ls -Srl *(.oL[1,10])"
# Display the ten newest directories and ten newest .directories
alias lsnewdir="command ls -rthdl *(/om[1,10]) .*(D/om[1,10])"
# Display the ten oldest directories and ten oldest .directories
alias lsolddir="command ls -rthdl *(/Om[1,10]) .*(D/Om[1,10])"

# ssh with StrictHostKeyChecking=no \\&\quad and UserKnownHostsFile unset
alias insecssh='ssh -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null"'
# scp with StrictHostKeyChecking=no \\&\quad and UserKnownHostsFile unset
alias insecscp='scp -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null"'

# use colors when GNU grep with color-support
if (( $#grep_options > 0 )); then
  o=${grep_options:+"${grep_options[*]}"}
  # Execute grep --color=auto
  alias grep='grep '$o
  alias egrep='egrep '$o
  unset o
fi

if ! type 'blaze' > /dev/null; then
  alias blaze='bazel'
fi

alias hl='hledger -f ~/gdrive/financials/personal.ledger'
if is-linux; then
  alias open='xdg-open'
fi

if is-darwin; then
  alias new-emacs='open -n /Applications/Emacs.app'
fi