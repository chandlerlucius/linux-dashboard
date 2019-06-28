#!/bin/sh

# PS4='+ $(date "+%s.%N")\011 '
# exec 3>&2 2>/tmp/bashstart.$$.log
# set -x

#Define all basic variables
DATE=$(date)
SECONDS=$(date -d "$DATE" +%s)
CONVERT=1048576

#Commands and Urls
#SSL_CHECK_URL="https://api.ssllabs.com/api/v3/analyze?host=$HOST_URL&publish=off&ignoreMismatch=on&all=done"

#Define necessary variables
export LC_ALL=C

#Define common functions
makeOrAddToGroup() {
    TITLE="$1"
    TYPE="$2"
    OBJECT="{ \"title\" : \"$TITLE\", \"type\" : \"$TYPE\", \"values\" : [$3] }"
    if [ "$4" != "" ]
    then
        echo "$4,$OBJECT"
    else
        echo "$OBJECT"
    fi
}

makeOrAddToValues() {
    TITLE="$1"
    TYPE="$2"
    THRESHOLD="$3"
    VALUE="$4"
    OBJECT="{ \"title\" : \"$TITLE\" , \"type\" : \"$TYPE\" , \"threshold\" : \"$THRESHOLD\" , \"value\" : \"$VALUE\" }"
    if [ "$5" != "" ]
    then
        echo "$5,$OBJECT"
    else
        echo "$OBJECT"
    fi
}

#Public IP Command
getPublicIP() {
    curl -sS -m 1 https://ipinfo.io/ip
}

#Private IP Command
getPrivateIP() {
    hostname -i
}

#Hostname Command
getHostname() {
    hostname
}

#Fully Qualified Domain Name Command
getFQDN() {
    hostname -f
}

#Top Command
getTop() {
    top -b -n2 -d1 -o %CPU | awk '/^top/{i++}i==2'
}

#Uptime Command
getUptime() {
    uptime -p
}

#Disk Free Command
getDiskFreeInfo() {
    df -hT | awk '{print $1"|"$2"|"$3"|"$4"|"$5"|"$6"|"$7}' | tr '\n' '#' | sed 's/\\/\//g'
}

if [ "$1" != "TEST" ] 
then
    #Run curl command to get IP info
    PUBLIC_IP=$(curl -sS -m 1 https://ipinfo.io/ip)

    #Run hostname commands to get network info
    HOSTNAME=$(hostname)
    PRIVATE_IP=$(hostname -i)
    FQDN=$(hostname -f)

    #Run top command to get cpu info
    TOP=$(top -b -n2 -d1 -o %CPU | awk '/^top/{i++}i==2')
    CPU=$(echo "$TOP" | sed -n -e 3p)
    CPU_PROCESSES=$(echo "$TOP" | tail -n +7 | awk '{print $1"|"$2"|"$9"|"$10"|"$12"|"$11}' | tr '\n' '#')

    #Run uptime command to get up time info
    UPTIME=$(uptime -p)

    #Run ps command to get processes info
    MEM_PROCESSES=$(ps axo "%p|%U|%C|" o "pmem" o "|%c|" o "rss" --sort=-pmem | tr '\n' '#' | tr -d ' ' | sed -r 's/(.*)#/\1/')

    #Run df command to get all disk info
    DF=$(df -hT | awk '{print $1"|"$2"|"$3"|"$4"|"$5"|"$6"|"$7}' | tr '\n' '#' | sed 's/\\/\//g')

    #Run free command to get mem & swap info
    FREE=$(free | tail -n 2)

    #Run df command to get root disk info
    DF_ROOT=$(df -PT / | tail -n 1)

    #Run dd command to get write info
    #DD=$(dd if=/dev/zero of=/tmp/output bs=8k count=10k 2>&1 | tail -n 1; rm -f /tmp/output;);

    #Parse /etc/passwd for user info
    USERS=$(printf "USERNAME|UID|GID|FULL NAME|HOME#" && awk -F ':' '{print $1"|"$3"|"$4"|"$5"|"$6}' /etc/passwd | tr '\n' '#')

    #Parse /etc/group for group info
    GRPS=$(printf "NAME|GID|USERS#" && awk -F ':' '{print $1"|"$3"|"$4}' /etc/group | tr '\n' '#')

    #Run last command to get last login info
    LOGINS=$(printf "USER|IP|LOGIN - LOGOUT|LENGTH#" && last -di | grep -v reboot | awk '{ printf $1"|"$3"|"; s = ""; for (i = 4; i <= NF; i++) s = s $i " "; print s }' | sed 's/ (/|/g' | tr -d ')' | sed '$d' | sed '$d' | tr '\n' '#')

    #Run netstat or ss command to get connection info
    NETSTAT=$(netstat >/dev/null 2>&1 | sed 1d; echo $?);
    SS=$(ss >/dev/null 2>&1 | sed 1d; echo $?);
    if [ "$NETSTAT" -eq 0 ]
    then
        CONNECTIONS=$(netstat -tu --numeric-hosts | awk '/EST/{print $4"|"$5}')
    elif [ "$SS" -eq 0 ]
    then
        CONNECTIONS=$(ss -tu | awk '/EST/{print $5"|"$6}')
    fi
    CONNECTION_HEADER=$(printf "PORT|IP|ORG|CITY|REGION|COUNTRY|POSTAL#")
    CONNECTION_INFO=$(printf "%s" "$CONNECTION_HEADER"; echo "$CONNECTIONS" | sed "s/$PRIVATE_IP://g" | grep -v "^127.\\|^:" | grep -Po ".*(?=:)" | tr '\n' '#')


    ##Build json objects

    #CPU
    DATA=""

    #CPU Used Chart
    CPU_USED_PCENT=$(echo "$CPU" | awk -F ':' '{print $2}' | sed 's/[,%]/ /g' | awk '{print $7}' | awk '{printf "%0.1f", 100 - $1}')
    TITLE="CPU Used"
    TYPE="chart"
    THRESHOLD="85"
    VALUE="$CPU_USED_PCENT"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #CPU Name
    TITLE="Name"
    TYPE="detail"
    THRESHOLD=""
    VALUE=$(grep -i 'model name' /proc/cpuinfo | tr -d '\t' | tail -1 | sed 's/model name: //g')
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #CPU Cores
    TITLE="Cores"
    TYPE="detail"
    THRESHOLD=""
    VALUE=$(nproc --all)
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #CPU Used
    TITLE="Used"
    TYPE="detail"
    THRESHOLD=""
    VALUE="$CPU_USED_PCENT%"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #CPU Group
    TITLE="CPU"
    TYPE="chart"
    GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")


    #Memory
    DATA=""
    MEM=$(echo "$FREE" | grep -i mem)

    #Memory Used Chart
    MEM_USED=$(echo "$MEM" | awk -v v1=$CONVERT '{printf "%0.1f", $3 / v1}')
    MEM_USED_PCENT=$(echo "$MEM" | awk '{printf "%0.1f", $3 / $2 * 100}')
    TITLE="Memory Used"
    TYPE="chart"
    THRESHOLD="70"
    VALUE="$MEM_USED_PCENT"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Memory Total
    MEM_TOTAL=$(echo "$MEM" | awk -v v1=$CONVERT '{printf "%0.1f", $2 / v1}')
    TITLE="Total"
    TYPE="detail"
    THRESHOLD=""
    VALUE="$MEM_TOTAL GB"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Memory Used
    TITLE="Used"
    TYPE="detail"
    THRESHOLD=""
    VALUE="$MEM_USED GB ($MEM_USED_PCENT%)"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Memory Free
    MEM_FREE=$(echo "$MEM" | awk -v v1=$CONVERT '{printf "%0.1f", $4 / v1}')
    MEM_FREE_PCENT=$(echo "$MEM" | awk '{printf "%0.1f", $4 / $2 * 100}')
    TITLE="Free"
    TYPE="detail"
    THRESHOLD=""
    VALUE="$MEM_FREE GB ($MEM_FREE_PCENT%)"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Memory Cache
    MEM_CACHE=$(echo "$MEM" | awk -v v1=$CONVERT '{printf "%0.1f", $6 / v1}')
    MEM_CACHE_PCENT=$(echo "$MEM" | awk '{printf "%0.1f", $6 / $2 * 100}')
    TITLE="Cache"
    TYPE="detail"
    THRESHOLD=""
    VALUE="$MEM_CACHE GB ($MEM_CACHE_PCENT%)"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Memory Group
    TITLE="Memory"
    TYPE="chart"
    GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")


    #Swap
    DATA=""
    SWAP=$(echo "$FREE" | grep -i swap)

    #Swap Used Chart
    SWAP_USED=$(echo "$SWAP" | awk -v v1=$CONVERT '{printf "%0.1f", $3 / v1}')
    SWAP_USED_PCENT=$(echo "$SWAP" | awk '{printf "%0.1f", $3 / $2 * 100}')
    TITLE="Swap Used"
    TYPE="chart"
    THRESHOLD="70"
    VALUE="$SWAP_USED_PCENT"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Swap Total
    SWAP_TOTAL=$(echo "$SWAP" | awk -v v1=$CONVERT '{printf "%0.1f", $2 / v1}')
    TITLE="Total"
    TYPE="detail"
    THRESHOLD=""
    VALUE="$SWAP_TOTAL GB"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Swap Used
    TITLE="Used"
    TYPE="detail"
    THRESHOLD=""
    VALUE="$SWAP_USED GB ($SWAP_USED_PCENT%)"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Swap Free
    SWAP_FREE=$(echo "$SWAP" | awk -v v1=$CONVERT '{printf "%0.1f", $4 / v1}')
    SWAP_FREE_PCENT=$(echo "$SWAP" | awk '{printf "%0.1f", $4 / $2 * 100}')
    TITLE="Free"
    TYPE="detail"
    THRESHOLD=""
    VALUE="$SWAP_FREE GB ($SWAP_FREE_PCENT%)"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Swap Group
    TITLE="Swap"
    TYPE="chart"
    GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")


    #CPU Processes
    DATA=""

    #CPU Process List
    TITLE="CPU Processes"
    TYPE="search"
    THRESHOLD=""
    VALUE="$CPU_PROCESSES"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #CPU Proccesses Group
    TITLE="CPU Proccesses"
    TYPE="search"
    GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")


    #MEM Processes
    DATA=""

    #MEM Process List
    TITLE="MEM Processes"
    TYPE="search"
    THRESHOLD=""
    VALUE="$MEM_PROCESSES"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #MEM Proccesses Group
    TITLE="MEM Proccesses"
    TYPE="search"
    THRESHOLD=""
    GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")

    #Status Tab
    TITLE="Status"
    TYPE="tab"
    TAB=$(makeOrAddToGroup "$TITLE" "$TYPE" "$GROUP" "$TAB")
    GROUP=""


    ##OS
    DATA=""

    #OS Name
    TITLE="Name"
    TYPE="detail"
    THRESHOLD=""
    VALUE=$(cat /etc/*release | grep ^NAME= | awk -F '=' '{print $2}' | tr -d '"')
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #OS Version
    TITLE="Version"
    TYPE="detail"
    THRESHOLD=""
    VALUE=$(cat /etc/*release | grep ^VERSION= | awk -F '=' '{print $2}' | tr -d '"')
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #OS Arch
    TITLE="Arch"
    TYPE="detail"
    THRESHOLD=""
    VALUE=$(uname -m)
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #OS Group
    TITLE="Operating System"
    TYPE="text"
    GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")


    ##Kernel
    DATA=""

    #Kernel Name
    TITLE="Name"
    TYPE="detail"
    THRESHOLD=""
    VALUE=$(uname -s)
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Kernel Release
    TITLE="Release"
    TYPE="detail"
    THRESHOLD=""
    VALUE=$(uname -r)
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Kernel Version
    TITLE="Version"
    TYPE="detail"
    THRESHOLD=""
    VALUE=$(uname -v)
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Kernel Group
    TITLE="Kernel"
    TYPE="text"
    GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")


    ##Time
    DATA=""

    #Time Name
    TITLE="Server Time"
    TYPE="detail"
    THRESHOLD=""
    VALUE=$(date)
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Up Time
    TITLE="Uptime"
    TYPE="detail"
    THRESHOLD=""
    VALUE="$UPTIME"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Time Group
    TITLE="Time"
    TYPE="text"
    GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")


    ##Users
    DATA=""

    #User List
    TITLE="Users"
    TYPE="search"
    THRESHOLD=""
    VALUE="$USERS"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Users Group
    TITLE="Users"
    TYPE="text"
    GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")


    ##Groups
    DATA=""

    #Group List
    TITLE="Groups"
    TYPE="search"
    THRESHOLD=""
    VALUE="$GRPS"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Groups Group
    TITLE="Groups"
    TYPE="text"
    GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")


    ##Logins
    DATA=""

    #Login List
    TITLE="Logins"
    TYPE="search"
    THRESHOLD=""
    VALUE="$LOGINS"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Logins Group
    TITLE="Logins"
    TYPE="text"
    GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")

    #General Tab
    TITLE="General"
    TYPE="tab"
    TAB=$(makeOrAddToGroup "$TITLE" "$TYPE" "$GROUP" "$TAB")
    GROUP=""


    ##Computer
    DATA=""

    #Computer Name
    TITLE="Host Name"
    TYPE="detail"
    THRESHOLD=""
    VALUE=$(getHostname)
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Computer URL
    TITLE="URL"
    TYPE="detail"
    THRESHOLD=""
    VALUE="$FQDN"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Computer Public IP
    TITLE="Public IP"
    TYPE="detail"
    THRESHOLD=""
    VALUE="$PUBLIC_IP"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Computer Private IP
    TITLE="Private IP"
    TYPE="detail"
    THRESHOLD=""
    VALUE="$PRIVATE_IP"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Computer Location
    # TITLE="Location"
    # VALUE="$LOCATION"
    # TYPE="detail"
    # DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Computer Group
    TITLE="Computer"
    TYPE="text"
    GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")


    ##Connection
    DATA=""

    #Connection IP List
    TITLE="IP List"
    TYPE="search"
    THRESHOLD=""
    VALUE="${CONNECTION_INFO}7131|23.228.172.13|[client-request]#443|72.182.66.65|[hidden]#"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Connection Group
    TITLE="Connections"
    TYPE="text"
    GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")

    #Network Tab
    TITLE="Network"
    TYPE="tab"
    TAB=$(makeOrAddToGroup "$TITLE" "$TYPE" "$GROUP" "$TAB")
    GROUP=""


    #Disk
    DATA=""

    #Disk Actvity Chart
    DISK_ACTIVITY_PCENT=$(echo "$CPU" | awk -F ':' '{print $2}' | sed 's/[,%]/ /g' | awk '{print $9}')
    TITLE="Disk Activity"
    TYPE="chart"
    THRESHOLD="85"
    VALUE="$DISK_ACTIVITY_PCENT"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Disk Type
    TITLE="Type"
    TYPE="detail"
    THRESHOLD=""
    VALUE=$(echo "$DF_ROOT" | awk '{print $2}')
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Disk Total
    DISK_TOTAL=$(echo "$DF_ROOT" | awk -v v1=$CONVERT '{printf "%0.1f", $3 / v1}')
    TITLE="Total"
    TYPE="detail"
    THRESHOLD=""
    VALUE="$DISK_TOTAL GB"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Disk Used
    DISK_USED=$(echo "$DF_ROOT" | awk -v v1=$CONVERT '{printf "%0.1f", $4 / v1}')
    DISK_USED_PCENT=$(echo "$DF_ROOT" | awk '{printf "%0.1f", $4 / $3 * 100}')
    TITLE="Used"
    TYPE="detail"
    THRESHOLD=""
    VALUE="$DISK_USED GB ($DISK_USED_PCENT%)"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Disk Free
    DISK_FREE=$(echo "$DF_ROOT" | awk -v v1=$CONVERT '{printf "%0.1f", $5 / v1}')
    DISK_FREE_PCENT=$(echo "$DF_ROOT" | awk '{printf "%0.1f", $5 / $3 * 100}')
    TITLE="Free"
    TYPE="detail"
    THRESHOLD=""
    VALUE="$DISK_FREE GB ($DISK_FREE_PCENT%)"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    # #Disk Write Speed
    # DISK_WRITE_SPEED=$(echo "$DD" | awk -F ',' '{print $4}' | sed 's/^[ ]//')
    # TITLE="Write Speed"
    # TYPE="detail"
    # VALUE="$DISK_WRITE_SPEED"
    # DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Disk Group
    TITLE="Root Disk"
    TYPE="chart"
    GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")


    #Disk Partitions
    DATA=""

    #Disk Partitions List
    TITLE="Disk Partitions"
    TYPE="search"
    THRESHOLD=""
    VALUE="$DF"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Disk Partitions Group
    TITLE="Disk Partitions"
    TYPE="search"
    GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")

    # #Biggest Files Info
    # BIGGEST_FILES=$(find ~ -type f -exec du -S {} + 2>/dev/null | sort -rn | head -n 5 | awk -v v1=$CONVERT '{printf "%0.3f", $1 / v1 * 1024; print " MB "$2 }' | perl -pe 's/\n/\\n\\n/g')
    # KEY="Biggest FIles"
    # VALUE="$BIGGEST_FILES"
    # RESULTS+=$($JQ -n --arg KEY "$KEY" --arg VALUE "$VALUE" --arg TYPE "$TYPE" --arg DISPLAY "$DISPLAY" \
    # '{ key : $KEY , value : $VALUE , type : $TYPE , display : $DISPLAY }')

    #IO Tab
    TITLE="IO"
    TYPE="tab"
    TAB=$(makeOrAddToGroup "$TITLE" "$TYPE" "$GROUP" "$TAB")
    GROUP=""


    #Put all the group data together
    echo "{ \"results\" : [ $TAB ] }"

    # set +x
    # exec 2>&3 3>&-

    # RESULTS=$($JQ -s . <<< "$RESULTS")

    #SSL Info
    # while true
    # do
    #     CURRENT_SECONDS=$(date +%s)
    #     SSL=$($CURL_COMMAND "$SSL_CHECK_URL" 2>&1);
    #     if [[ "$SSL" == *"timed out"* ]]
    #     then
    #         SSL_INFO="Server may be down at SSLLABS - $SSL"
    #         break
    #     else
    #         SSL_INFO=$($JQ -r .endpoints[0].progress <<< "$SSL" 2>&1)
    #     fi
    #     if [[ "$SSL_INFO" == "100" ]]
    #     then
    #         SSL_INFO=$($JQ -r .endpoints[0].grade <<< "$SSL")
    #         break
    #     else
    #         sleep 10
    #     fi
    # done
    # KEY="SSL"
    # VALUE="$SSL_INFO"
    # SERVER_INFO+=$($JQ -n --arg KEY "$KEY" --arg VALUE "$VALUE" --arg TYPE "$TYPE" --arg DISPLAY "$DISPLAY" \
    # '{ key : $KEY , value : $VALUE , type : $TYPE , display : $DISPLAY }')
    # SERVER_INFO=$($JQ -s . <<< "$SERVER_INFO")

    ##Problem Checking
    #Disk Used Check
    # DISK_USED_EMERGENCY=$(grep -i "disk used" $THRESHOLDS_FILE | awk -F '|' '{print $2}' | xargs)
    # DISK_USED_WARNING=$(grep -i "disk used" $THRESHOLDS_FILE | awk -F '|' '{print $3}' | xargs)
    # STATUS=0
    # if [[ $DISK_USED_PCENT -gt $DISK_USED_EMERGENCY ]]
    # then
    #   STATUS=2
    # elif [[ $DISK_USED_PCENT -gt $DISK_USED_WARNING ]]
    # then
    #   STATUS=1
    # fi
    # if [[ $STATUS -ne 0 ]]
    # then
    #   RESULTS=$($JQ --arg STATUS $STATUS '.[] | select(.id == "diskUsed") |= .+ {"status" : $STATUS}' <<< "$RESULTS")
    #   RESULTS=$($JQ -s . <<< "$RESULTS")
    # fi

    # #Disk Free Check
    # DISK_FREE_EMERGENCY=$(grep -i "disk used" $THRESHOLDS_FILE | awk -F '|' '{print 100 - $2}' | xargs)
    # DISK_FREE_WARNING=$(grep -i "disk used" $THRESHOLDS_FILE | awk -F '|' '{print 100 - $3}' | xargs)
    # STATUS=0
    # if [[ $DISK_FREE_PCENT -lt $DISK_FREE_EMERGENCY ]]
    # then
    #   KEY="Extremely Low Disk Space"
    #   STATUS=2
    # elif [[ $DISK_FREE_PCENT -lt $DISK_FREE_WARNING ]]
    # then
    #   KEY="Low Disk Space"
    #   STATUS=1
    # fi
    # if [[ $STATUS -ne 0 ]]
    # then
    #   VALUE="This server has $DISK_FREE_PCENT% remaining disk space. Only $DISK_FREE GB remaining."
    #   RESULTS=$($JQ --arg STATUS $STATUS '.[] | select(.id == "diskFree") |= .+ {"status" : $STATUS}' <<< "$RESULTS")
    #   RESULTS=$($JQ -s . <<< "$RESULTS")
    #   PROBLEMS+=$($JQ -n --arg KEY "$KEY" --arg VALUE "$VALUE" --arg TYPE "$TYPE" --arg DISPLAY "$DISPLAY" --arg STATUS "$STATUS" \
    #   '{ key : $KEY , value : $VALUE , type : $TYPE , display : $DISPLAY , status : $STATUS }')
    # fi

    # #CPU Check
    # CPU_AVERAGE_EMERGENCY=$(grep -i "cpu average" $THRESHOLDS_FILE | awk -F '|' '{print $2}' | xargs)
    # CPU_AVERAGE_WARNING=$(grep -i "cpu average" $THRESHOLDS_FILE | awk -F '|' '{print $3}' | xargs)
    # STATUS=0
    # if [[ $CPU_AVERAGE -gt $CPU_AVERAGE_EMERGENCY ]]
    # then
    #   KEY="Extremely High CPU Usage"
    #   STATUS=2
    # elif [[ $CPU_AVERAGE -gt $CPU_AVERAGE_WARNING ]]
    # then
    #   KEY="High CPU Usage"
    #   STATUS=1
    # fi
    # if [[ $STATUS -ne 0 ]]
    # then
    #   VALUE="This server has averaged $CPU_AVERAGE% of the total CPU in the last $TOP_INTERVAL minutes."
    #   PROBLEMS+=$($JQ -n --arg KEY "$KEY" --arg VALUE "$VALUE" --arg TYPE "$TYPE" --arg DISPLAY "$DISPLAY" --arg STATUS "$STATUS" \
    #   '{ key : $KEY , value : $VALUE , type : $TYPE , display : $DISPLAY , status : $STATUS }')
    # fi

    # #Memory Check
    # MEM_AVERAGE_EMERGENCY=$(grep -i "mem average" $THRESHOLDS_FILE | awk -F '|' '{print $2}' | xargs)
    # MEM_AVERAGE_WARNING=$(grep -i "mem average" $THRESHOLDS_FILE | awk -F '|' '{print $3}' | xargs)
    # STATUS=0
    # if [[ $MEM_AVERAGE -gt $MEM_AVERAGE_EMERGENCY ]]
    # then
    #   KEY="Extremely High Memory Usage"
    #   STATUS=2
    # elif [[ $MEM_AVERAGE -gt $MEM_AVERAGE_WARNING ]]
    # then
    #   KEY="High Memory Usage"
    #   STATUS=1
    # fi
    # if [[ $STATUS -ne 0 ]]
    # then
    #   VALUE="This server has averaged $MEM_AVERAGE% of the total memory in the last $TOP_INTERVAL minutes."
    #   PROBLEMS+=$($JQ -n --arg KEY "$KEY" --arg VALUE "$VALUE" --arg TYPE "$TYPE" --arg DISPLAY "$DISPLAY" --arg STATUS "$STATUS" \
    #   '{ key : $KEY , value : $VALUE , type : $TYPE , display : $DISPLAY , status : $STATUS }')
    # fi

    # #Swap Check
    # SWAP_AVERAGE_EMERGENCY=$(grep -i "swap average" $THRESHOLDS_FILE | awk -F '|' '{print $2}' | xargs)
    # SWAP_AVERAGE_WARNING=$(grep -i "swap average" $THRESHOLDS_FILE | awk -F '|' '{print $3}' | xargs)
    # STATUS=0
    # if [[ $SWAP_AVERAGE -gt $SWAP_AVERAGE_EMERGENCY ]]
    # then
    #   KEY="Extremely High Swap Usage"
    #   STATUS=2
    # elif [[ $SWAP_AVERAGE -gt $SWAP_AVERAGE_WARNING ]]
    # then
    #   KEY="High Swap Usage"
    #   STATUS=1
    # fi
    # if [[ $STATUS -ne 0 ]]
    # then
    #   VALUE="This server has averaged $SWAP_AVERAGE% of the total swap in the last $TOP_INTERVAL minutes."
    #   PROBLEMS+=$($JQ -n --arg KEY "$KEY" --arg VALUE "$VALUE" --arg TYPE "$TYPE" --arg DISPLAY "$DISPLAY" --arg STATUS "$STATUS" \
    #   '{ key : $KEY , value : $VALUE , type : $TYPE , display : $DISPLAY , status : $STATUS }')
    # fi

    # #SSL Check
    # SSL_EMERGENCY=$(grep -i "ssl" $THRESHOLDS_FILE | awk -F '|' '{print $2}' | awk '{print $2}')
    # if [[ "$SSL_INFO" != "$SSL_EMERGENCY" ]]
    # then
    #     if [[ "$SSL_INFO" != "$SSL_EMERGENCY+" ]]
    #     then
    #         if [[ "$SSL_INFO" != "$SSL_EMERGENCY-" ]] && [[ "$SSL_INFO" != "B" ]]
    #         then
    #         KEY="SSL Failure"
    #         VALUE="This server failed the ssl check with the grade: $SSL_INFO"
    #         STATUS=2
    #         SERVER_INFO=$($JQ --arg STATUS $STATUS '.[] | select(.id == "sslStatus") |= .+ {"status" : $STATUS}' <<< "$SERVER_INFO")
    #         SERVER_INFO=$($JQ -s . <<< "$SERVER_INFO")
    #         if [[ "$SSL_INFO" != *"timed out"* ]]
    #         then
    #             PROBLEMS+=$($JQ -n --arg KEY "$KEY" --arg VALUE "$VALUE" --arg TYPE "$TYPE" --arg DISPLAY "$DISPLAY" --arg STATUS "$STATUS" \
    #             '{ key : $KEY , value : $VALUE , type : $TYPE , display : $DISPLAY , status : $STATUS }')
    #         fi
    #         else
    #         STATUS=1
    #         SERVER_INFO=$($JQ --arg STATUS $STATUS '.[] | select(.id == "sslStatus") |= .+ {"status" : $STATUS}' <<< "$SERVER_INFO")
    #         SERVER_INFO=$($JQ -s . <<< "$SERVER_INFO")
    #         fi
    #     fi
    # fi

    #Add Data to Final JSON
    #DATA_INFO=$($JQ ".dataPoints |= $RESULTS" <<< "$DATA_INFO")
    # if [[ "$SERVER_INFO" != "" ]]
    # then
    #   DATA_INFO=$($JQ ".serverStatus |= $SERVER_INFO" <<< "$DATA_INFO")
    # fi
    # DATA_INFO=$($JQ ".lastUpdate |=  $SECONDS" <<< "$DATA_INFO")
    # DATA_INFO=$($JQ ".topInfo |= $TOP_INFO" <<< "$DATA_INFO")

    #PROBLEMS=$($JQ -s . <<< "$PROBLEMS")

    #$JQ ".problems |= $PROBLEMS" <<< "$DATA_INFO"

    #RESULTS=$($JQ -s . <<< "$RESULTS")
    #$JQ -Rn ".results |= $RESULTS"
fi