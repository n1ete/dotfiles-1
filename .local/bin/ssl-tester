#!/bin/bash -e
########################################################################
#** Version: 1.0
#* This script gives a hand in testing ssl connections as remembering
#* all that openssl commands was to much for my small brain. Default
#* port is HTTPS.
#
# note: the frame for this script was auto-created with
# *https://github.com/inofix/admin-toolbox/blob/master/makebashscript.sh*
########################################################################
# author/copyright: <mic@inofix.ch>
# license: gladly sharing with the universe and any lifeform,
#          be it naturally born or constructed, alien or kin..
#          USE AT YOUR OWN RISK.
########################################################################
[ "$1" == "debug" ] && shift && set -x

## variables ##

### you may copy the following variables into this file for having your own
### local config ...
#conffile=~/.ssl-tester.sh

### {{{

dryrun=1
needsroot=1
# list all available protocols that might be tested
protocol_list="ssl3 tls1 tls1_1 tls1_2"
# protocol settings to use in default tests
protocol_prefs="no_ssl3 no_tls1"
# considered ok
ok_protocols="tls1"
# considered safe
safe_protocols="tls1_1 tls1_2"
# cipher suite to use in default tests
ciphers=''
safe_ciphers='HIGH:!DSS:!aNULL@STRENGTH'
verbose=0

### }}}

starttls=""

# Unsetting this helper variable
_pre=""

# The system tools we gladly use. Thank you!
declare -A sys_tools
sys_tools=(
    ["_awk"]="/usr/bin/awk"
    ["_grep"]="/bin/grep"
    ["_id"]="/usr/bin/id"
    ["_openssl"]="/usr/bin/openssl"
    ["_pwd"]="/bin/pwd"
    ["_sed"]="/bin/sed"
    ["_tr"]="/usr/bin/tr"
)
# this tools get disabled in dry-run and sudo-ed for needsroot
danger_tools=( "_sed" )
# special case sudo (not mandatory)
_sudo="/usr/bin/sudo"

## functions ##

print_usage()
{
    echo "usage: $0 action [servername] [port]"
}

print_help()
{
    print_usage
    $_grep "^#\* " $0 | $_sed 's;^#\*;;'
}

print_version()
{
    $_grep "^#\*\* " $0 | $_sed 's;^#\*\*;;'
}

die()
{
    echo "$@"
    exit 1
}

error()
{
    print_usage
    echo ""
    die "Error: $@"
}

## logic ##

## first set the system tools
for t in ${!sys_tools[@]} ; do
    if [ -x "${sys_tools[$t]##* }" ] ; then
        export ${t}="${sys_tools[$t]}"
    else
        error "Missing system tool: ${sys_tools[$t]##* } must be installed."
    fi
done

[ -r "$conffile" ] && . $conffile

#* options:
while true ; do
    case "$1" in
#*      -c |--config conffile               alternative config file
        -c|--config)
            shift
            if [ -r "$1" ] ; then
                . $1
            else
                die " config file $1 does not exist."
            fi
        ;;
#*      -C |--ciphers [cifer:..]|all|safe   consider all ciphers
        -C|--ciphers)
            shift
            ciphers=$1
            case "$1" in
                a*)
                    ciphers='ALL:eNULL'
                ;;
                s*)
                    ciphers="$safe_ciphers"
                ;;
                *)
                    ciphers="$1"
                ;;
            esac
        ;;
#*      -h |--help                          print this help
        -h|--help)
            print_help
            exit 0
        ;;
#*      -p |--protocols 'list'              a space separated list of protocol
#*                                          options  e.g. -no_ssl3 (see
#*                                          'man s_client')
        -p|--protocols)
            shift
            protocol_prefs="$1"
        ;;
#*      -P |--safe-protocol                 test only protocols considered
#*                                          "safe"
        -P|--safe*)
            protocol_prefs="$safe_protocols"
        ;;
#*      -q |--quiet                         contrary of verbose (see config)
        -q|--quiet)
            verbose=1
        ;;
#*      -s |--starttls protocol             use starttls (see 'man s_client')
        -s|--starttls)
            shift
            starttls="-starttls $1"
        ;;
#*      -v |--verbose                       contrary of quiet (see config)
        -v|--verbose)
            verbose=0
        ;;
#*      -V |--version                       print the version information
        -V|--version)
            print_version
            exit
        ;;
        -*|--*)
            error "option $1 not supported"
        ;;
        *)
            break
        ;;
    esac
    shift
done

if [ $dryrun -eq 0 ] ; then
    _pre="echo "
fi

if [ $needsroot -eq 0 ] ; then

    iam=$($_id -u)
    if [ $iam -ne 0 ] ; then
        if [ -x "$_sudo" ] ; then

            _pre="$_pre $_sudo"
        else
            error "Missing system tool: $_sudo must be installed."
        fi
    fi
fi

for t in ${danger_tools[@]} ; do
    export ${t}="$_pre ${sys_tools[$t]}"
done

host=${2:-localhost}
port=${3:-443}

connect()
{
    $_openssl s_client $starttls $ssl_protocols -connect $1:$2 2>&1
}

try_connect()
{
    echo "" | $_openssl s_client -servername $1 $starttls $ssl_protocols -connect $1:$2 2>&1
}

list_ciphers()
{
    $_openssl ciphers $1 | $_sed 's;:; ;g'
}

get_certs()
{
    try_connect $1 $2 | \
        $_awk 'BEGIN {printout=1;} \
                /-----BEGIN CERTIFICATE-----/ {printout=0;} \
                /-----END CERTIFICATE-----/ {printout=1; print $0} \
                {if (printout == 0) print $0}'
}

print_summary()
{
    get_certs $1 $2 | $_openssl x509 -noout -text | \
        $_grep -A1 -e "Version: " -e "Signature Algorithm:" \
                    -e "Not Before:" -e "Subject:" -e "Public-Key:" \
                    -e "X509v3 Subject Key Identifier:" \
                    -e "X509v3 Subject Alternative Name:" \
                    -e "Authority Information Access:" \
                    -e "CA Issuers" | \
            $_sed 's/^ */ /' | \
            $_grep -v -e "--" -e "Modulus:" -e "Subject Public Key Info:" | \
            $_awk '/^\s$/ {exit}; {print $0};'
}

print_validity()
{
    get_certs $1 $2 | $_openssl x509 -noout -text | \
        $_grep -A1 -e "Serial Number:" -e "Not Before:" | \
        $_sed 's/^ */ /' | $_grep -v -e "--"
}

print_hostnames()
{
    get_certs $1 $2 | $_openssl x509 -noout -text | \
        $_grep -e "Subject:" -e "DNS:"
}

ssl_protocols=""
for p in $protocol_prefs ; do
    ssl_protocols="$ssl_protocols -$p"
done

#* actions:
case $1 in
#*      certs                       show the certificates involved
    cert*)
        try_connect $host $port -showcerts
        ;;
#*      ciphers                     test the cipher suite support on a server
    cip*)
        echo "Testing cipher suite on $host $port:"
        safe_cipher_list=" $(list_ciphers $safe_ciphers) "
        for c in $(list_ciphers $ciphers) ; do
            if [ "XXX" == "${safe_cipher_list/* $c */XXX}" ] ; then
                marker="\e[1;32m*"
            else
                marker="\e[1;31m@"
            fi
            retval=0
            res=$(try_connect $host $port "-cipher $c") || retval=1
            if [ $retval -eq 0 ] ; then
                echo -e "\e[0;39m[$marker\e[0;39m] \e[1m$c"
            else
                if [ $verbose -eq 0 ] ; then
                    res=$( echo -n $res | cut -d':' -f6)
#TODO add a list of safe/ok ciphers, like in protocols
                    echo -e "\e[0;39m[ ] $c \e[0;33m$res"
                fi
            fi
        done
        ;;
#*      connect                     open a connection and hold it
    connect|open)
        connect $host $port
        ;;
#*      connect-test                just try to connect
    connect-test|test|try)
        try_connect $host $port
        ;;
#*      help                        print help
    help)
        print_help
        ;;
#*      list-ciphers                list the ciphers available locally
    ls|list*)
        for c in $(list_ciphers $ciphers) ; do
            echo $c
        done
        ;;
#*      print-cert                  print just the certificate
    print-cert)
        get_certs $host $port
    ;;
#*      print-certs                 print just the certificates involved
    print-certs)
        get_certs $host $port -showcerts
    ;;
    print-host*|host*|print-san|san)
        IFSOLD=$IFS
        IFS="$(echo -ne '\n\b')"
        info=( $(IFS=$IFSOLD; print_hostnames $host $port) )
        IFS=","
        holder=( $( echo "${info[0]#*:}" ) )
        IFS=$IFSOLD
    ;;&
#*      print-hostnames             print all the hostnames protected
    print-host*|host*)
        echo "This certificate was issued for:"
        for (( i=0; i<${#holder[@]}; i++ )); do
            echo -e " $(echo ${holder[$i]} | $_sed 's@CN@\\e[1;33mCN@') "\
                    "\e[0;39m"
        done
    ;&
#*      print-san                   print alternative hostname entries
    print-san|san)
#        a=$(echo ${holder[0]#*:} | $_sed 's@CN@\\e[0;39mCN@')
        echo "The following hostnames (SAN) are registered:"
        echo -e -n "\e[0;33m"
        for h in ${info[1]} ; do
            h=${h#*:}
            echo "    ${h%,}"
        done
    ;;
#*      print-summary               print an overview of the certificate
    print-sum*|sum*)
        print_summary $host $port
    ;;
#*      print-validity              print an overview of the certificate
    print-val*|val*)
        print_validity $host $port
    ;;
#*      protocols                   test the protocol support on a server
    prot*)
        for p in $protocol_list ; do
            ssl_protocols="-$p"
            retval=0
            res=$(try_connect $host $port) || retval=1
            safeval=2
            for s in $safe_protocols ; do
                if [ "$s" == "$p" ] ; then
                    safeval=0
                    break
                fi
            done
            if [ $safeval -gt 0 ] ; then
                for s in $ok_protocols ; do
                    if [ "$s" == "$p" ] ; then
                        safeval=1
                        break
                    fi
                done
            fi
            if [ $retval -eq 0 ] ; then
                if [ $safeval -eq 0 ] ; then
                    color="\e[1;32m"
                elif [ $safeval -eq 1 ] ; then
                    color="\e[1;33m"
                elif [ $safeval -eq 2 ] ; then
                    color="\e[1;31m"
                fi
                echo -e "\e[0;39m[$color*\e[1;39m] $p"
            else
                if [ $verbose -eq 0 ] ; then
                    res=$( echo -n $res | cut -d':' -f6)
                    echo -e "\e[0;39m[ ] $p \e[0;33m$res"
                fi
            fi
        done
        ;;
    *)
        error "not supported.."
        ;;
esac

