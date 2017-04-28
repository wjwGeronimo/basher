# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

### Define some var's
OS=`uname`
if [ "$OS" = "FreeBSD" ]
then
    WG="/usr/local/bin/wget -T 3 -q --no-check-certificate"
    MD="/sbin/md5"
    O=$($MD ~/.bashrc | awk '{print $NF}' )
    SUDOFILE="/usr/local/etc/sudoers"
    SEDC="sed -i ''"
elif [ "$OS" = "Linux" ]
then
    WG="/usr/bin/wget -T 3 -q --no-check-certificate"
    MD="/usr/bin/md5sum"
    O=$($MD ~/.bashrc | awk '{print $1}' )
    SUDOFILE="/etc/sudoers"
    SEDC="sed -i"
else
    echo "Can't detect system"
fi
### Update my bashrc
# Dont forget to make `md5sum bashrc > bashrc.md5` after change this file
# Better use /home/vzhilkin/bashrc_up script
bashup() {
    $WG -O ~/bashrc_new https://mnt.itmm.ru/pub/vzhilkin/bashrc
    OS=`uname`
    if [ "$OS" = "Linux" ]
    then
        THIS=$($MD ~/bashrc_new | awk '{print $1}' )
    elif [ "$OS" = "FreeBSD" ]
    then
        THIS=$($MD ~/bashrc_new | awk '{print $NF}' )
    fi
    if [ "$THIS" = "$1" ]
    then
        mv ~/bashrc_new ~/.bashrc
        echo -e "BashRC Updated!\nApplying..."
        source ~/.bashrc
    else
        echo -e "MD5 mismatch...\nSomething wrong..."
    fi
}
$WG -O /tmp/vz.md5 https://mnt.itmm.ru/pub/vzhilkin/bashrc.md5
N=$(cat /tmp/vz.md5 | awk '{print $1}')
[ "$N" != "$O" ] && rm -f /tmp/vz.md5 /tmp/old.md5 && bashup $N || rm -f /tmp/vz.md5 /tmp/old.md5
###

# User specific aliases and functions

### exports
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
###

### test for some needed files
[ -f ~/.vimrc ] || touch ~/.vimrc
[ -f ~/.bash_profile ] || $WG -O ~/.bash_profile https://mnt.itmm.ru/pub/vzhilkin/bash_profile
[ -f ~/.profile ] || $WG -O ~/.profile https://mnt.itmm.ru/pub/vzhilkin/bash_profile
$WG -O ~/mycalc.sh https://mnt.itmm.ru/pub/vzhilkin/mycalc.sh && chmod +x ~/mycalc.sh
### PS1
# Colors
Red='\[\033[0;31m\]'
Cyan='\[\033[0;36m\]'
FRed='\[\033[1;31m\]'
FGreen='\[\033[1;32m\]'
FBlue='\[\033[1;34m\]'
FCyan='\[\033[1;36m\]'
UGreen='\[\033[4;32m\]'
CReset='\[\033[0m\]'

if [ `id -u` = 0 ]
then
        #PS1="${Cyan}\t${CReset} ${Red}\u${CReset}@${UGreen}\h${CReset} ${FBlue}[\w]${CReset} ${FRed}\$${CReset} "
        PS1="${Cyan}\t${CReset} ${UGreen}\h${CReset}${FBlue}[\w]${CReset}${FRed}\$${CReset} "
        PS2="${Red}\$${CReset}=> "
else
        #PS1="${Cyan}\u${CReset}@${UGreen}\h${CReset} ${FBlue}[\w]${CReset} ${FCyan}\$${CReset} "
        #PS2="${Cyan}\$${CReset}=> "
        PS1="\u@\h[\w]~ "
        PS2="~=> "
fi
###

### Various bashrc
[ -f ~/.bashrc_spec ] && source ~/.bashrc_spec
###

### Aliases
alias ll="ls -lah"
alias wgnc="wget --no-check-certificate"
alias wgbvh="mkdir /usr/build; wget --no-check-certificate https://mnt.itmm.ru/pub/conf-reglament/Soft/build_vsa_huinya.sh -O /usr/build/build_vsa_huinya.sh"
alias pp="ps u"
alias ps="ps waxf"
#alias chmor="chmod -R"
alias kurl="curl -k"
if [ "$OS" = "Linux" ];then
alias iplist="iptables -vnL"
alias ipsave="iptables-save > /etc/sysconfig/iptables"
alias ipflush="iptables -F; iptables -F -t nat; iptables -F -t raw"
alias clmem="free -m && sync && echo 3 > /proc/sys/vm/drop_caches && free -m"
alias netlist="netstat -ntlp"
alias cldmesg="dmesg -c"
fi
if [ "$OS" = "FreeBSD" ];then
alias iplist="ipfw show"
alias cldmesg="sysctl kern.msgbuf_clear=1"
fi
[ -x /usr/sbin/named-checkconf ] && alias nmcheck="named-checkconf -zj > /dev/null;echo $?"
###

### Exports
DIRS="/root/bin /root/mk /var/mk/stable/bin /opt/MegaRAID/storcli /opt/puppetlabs/bin /opt/zimbra/bin"
for DIR in $DIRS
do
    [ -d "$DIR" ] && export PATH=$PATH:$DIR
done
###
