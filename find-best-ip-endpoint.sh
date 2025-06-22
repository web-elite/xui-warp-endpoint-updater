#!/bin/bash

INSTALL_DIR="/root/xui-warp-endpoint-updater"
FILE="$INSTALL_DIR/result.csv"

#colors
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
purple='\033[0;35m'
cyan='\033[0;36m'
rest='\033[0m'

case "$(uname -m)" in
x86_64 | x64 | amd64)
    cpu=amd64
    ;;
i386 | i686)
    cpu=386
    ;;
armv8 | armv8l | arm64 | aarch64)
    cpu=arm64
    ;;
armv7l)
    cpu=arm
    ;;
*)
    echo "The current architecture is $(uname -m), not supported"
    exit
    ;;
esac

cfwarpIP() {
    local cpu_file="$INSTALL_DIR/cpu/$cpu"

    if [[ ! -f "$cpu_file" ]]; then
        echo "Downloading warpendpoint program for CPU: $cpu"
        mkdir -p "$INSTALL_DIR/cpu"
        curl -L -o warpendpoint -# --retry 2 https://raw.githubusercontent.com/web-elite/xui-warp-endpoint-updater/main/cpu/$cpu
        cp warpendpoint $PREFIX/bin
        chmod +x $PREFIX/bin/warpendpoint
    else
        echo "warpendpoint program already exists at $cpu_file"
    fi
}

endipv4() {
    n=0
    iplist=100
    while true; do
        temp[$n]=$(echo 162.159.192.$(($RANDOM % 256)))
        n=$(($n + 1))
        if [ $n -ge $iplist ]; then
            break
        fi
        temp[$n]=$(echo 162.159.193.$(($RANDOM % 256)))
        n=$(($n + 1))
        if [ $n -ge $iplist ]; then
            break
        fi
        temp[$n]=$(echo 162.159.195.$(($RANDOM % 256)))
        n=$(($n + 1))
        if [ $n -ge $iplist ]; then
            break
        fi
        temp[$n]=$(echo 188.114.96.$(($RANDOM % 256)))
        n=$(($n + 1))
        if [ $n -ge $iplist ]; then
            break
        fi
        temp[$n]=$(echo 188.114.97.$(($RANDOM % 256)))
        n=$(($n + 1))
        if [ $n -ge $iplist ]; then
            break
        fi
        temp[$n]=$(echo 188.114.98.$(($RANDOM % 256)))
        n=$(($n + 1))
        if [ $n -ge $iplist ]; then
            break
        fi
        temp[$n]=$(echo 188.114.99.$(($RANDOM % 256)))
        n=$(($n + 1))
        if [ $n -ge $iplist ]; then
            break
        fi
    done
    while true; do
        if [ $(echo "${temp[@]}" | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]; then
            break
        else
            temp[$n]=$(echo 162.159.192.$(($RANDOM % 256)))
            n=$(($n + 1))
        fi
        if [ $(echo "${temp[@]}" | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]; then
            break
        else
            temp[$n]=$(echo 162.159.193.$(($RANDOM % 256)))
            n=$(($n + 1))
        fi
        if [ $(echo "${temp[@]}" | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]; then
            break
        else
            temp[$n]=$(echo 162.159.195.$(($RANDOM % 256)))
            n=$(($n + 1))
        fi
        if [ $(echo "${temp[@]}" | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]; then
            break
        else
            temp[$n]=$(echo 188.114.96.$(($RANDOM % 256)))
            n=$(($n + 1))
        fi
        if [ $(echo "${temp[@]}" | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]; then
            break
        else
            temp[$n]=$(echo 188.114.97.$(($RANDOM % 256)))
            n=$(($n + 1))
        fi
        if [ $(echo "${temp[@]}" | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]; then
            break
        else
            temp[$n]=$(echo 188.114.98.$(($RANDOM % 256)))
            n=$(($n + 1))
        fi
        if [ $(echo "${temp[@]}" | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]; then
            break
        else
            temp[$n]=$(echo 188.114.99.$(($RANDOM % 256)))
            n=$(($n + 1))
        fi
    done
}

endipresult() {
    echo "${temp[@]}" | sed -e 's/ /\n/g' | sort -u >ip.txt
    ulimit -n 102400
    chmod +x warpendpoint >/dev/null 2>&1
    if command -v warpendpoint &>/dev/null; then
        warpendpoint
    else
        ./warpendpoint
    fi

    clear
    # اگر فایل وجود نداشت، فایل خالی بساز
    if [[ ! -f "$FILE" ]]; then
        echo "File $FILE not found! Creating empty file..."
        >"$FILE"
    fi

    # ادامه پردازش فقط اگر فایل خالی نباشه
    if [[ ! -s "$FILE" ]]; then
        echo "File $FILE is empty. Nothing to process."
        exit 0
    fi

    # فیلتر و مرتب‌سازی داده‌ها
    awk -F, '$3 != "timeout ms"' "$FILE" | sort -t, -nk2 -nk3 | uniq | head -11 |
        awk -F, '{print "Endpoint " $1 " Packet Loss Rate " $2 " Average Delay " $3}'

    # استخراج اولین IPv4 با پورت
    Endip_v4=$(grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+" "$FILE" | head -n1)
    # استخراج اولین IPv6 با پورت
    Endip_v6=$(grep -oE "\[[0-9a-fA-F:]+\]:[0-9]+" "$FILE" | head -n1)
    # استخراج اولین مقدار delay یا timeout
    delay=$(grep -oE "[0-9]+ ms|timeout" "$FILE" | head -n1)
    # echo ""
    # echo -e "${green}Results Saved in result.csv${rest}"
    # echo ""
    # if [ "$Endip_v4" ]; then
    #     echo -e "${purple}************************************${rest}"
    #     echo -e "${purple}*           ${yellow}Best IPv4:Port${purple}         *${rest}"
    #     echo -e "${purple}*                                  *${rest}"
    #     echo -e "${purple}*          ${cyan}$Endip_v4${purple}     *${rest}"
    #     echo -e "${purple}*           ${cyan}Delay: ${green}[$delay]        ${purple}*${rest}"
    #     echo -e "${purple}************************************${rest}"
    # elif [ "$Endip_v6" ]; then
    #     echo -e "${purple}********************************************${rest}"
    #     echo -e "${purple}*          ${yellow}Best [IPv6]:Port                ${purple}*${rest}"
    #     echo -e "${purple}*                                          *${rest}"
    #     echo -e "${purple}* ${cyan}$Endip_v6${purple} *${rest}"
    #     echo -e "${purple}*           ${cyan}Delay: ${green}[$delay]               ${purple}*${rest}"
    #     echo -e "${purple}********************************************${rest}"
    # else
    #     echo -e "${red} No valid IP addresses found.${rest}"
    # fi
    rm warpendpoint >/dev/null 2>&1
    rm -rf ip.txt
    exit
}

endipv6() {
    n=0
    iplist=100
    while true; do
        temp[$n]=$(echo [2606:4700:d0::$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2))):$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2))):$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2))):$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2)))])
        n=$(($n + 1))
        if [ $n -ge $iplist ]; then
            break
        fi
        temp[$n]=$(echo [2606:4700:d1::$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2))):$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2))):$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2))):$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2)))])
        n=$(($n + 1))
        if [ $n -ge $iplist ]; then
            break
        fi
    done
    while true; do
        if [ $(echo "${temp[@]}" | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]; then
            break
        else
            temp[$n]=$(echo [2606:4700:d0::$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2))):$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2))):$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2))):$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2)))])
            n=$(($n + 1))
        fi
        if [ $(echo "${temp[@]}" | sed -e 's/ /\n/g' | sort -u | wc -l) -ge $iplist ]; then
            break
        else
            temp[$n]=$(echo [2606:4700:d1::$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2))):$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2))):$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2))):$(printf '%x\n' $(($RANDOM * 2 + $RANDOM % 2)))])
            n=$(($n + 1))
        fi
    done
}

clear
cfwarpIP
endipv4
endipresult
# Endip_v4
