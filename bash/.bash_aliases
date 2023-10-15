#Shell
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

#Networking
alias eth0='enp0s25'
alias morpheusssh='ssh -p 10024 modengo@192.168.2.185'
alias bladessh='ssh -p 10025 blade@192.168.2.186'
alias orico01s='sshfs -p 10024 modengo@192.168.2.185:/mnt/Orico01S /mnt/Orico01S/'
alias orico02t='sshfs -p 10024 modengo@192.168.2.185:/mnt/Orico02T /mnt/Orico02T/'

#Scripts
alias pressao='bash /gitclones/pressao/pressao'
alias shelltimer='bash /gitclones/shelltimer/shelltimer.sh'
alias pomodoro='/gitclones/pomodoro/pomodoro.sh'
alias yourl='/gitclones/yoURL/yourl.sh'
alias passgen='/gitclones/shellPass/shellPass.sh'
alias i3conf='vim ${HOME}/.config/i3/config'
alias i3conf='vim ${HOME}/.config/i3/config'
alias qrshell='bash /gitclones/qrshell/qrshell.sh'

#Kubernetes
alias k='kubectl'

