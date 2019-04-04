#!/bin/bash

#Set maximum virtual memory for this script
ulimit -Sv 2194304

#Define all basic variables
DATE=$(date)
SECONDS=$(date -d "$DATE" +%s)
CONVERT=1048576

#Commands and Urls
SSL_CHECK_URL="https://api.ssllabs.com/api/v3/analyze?host=$HOST_URL&publish=off&ignoreMismatch=on&all=done"

#Define all files
JQ="./jq-linux64"
THRESHOLDS_FILE="./thresholds.txt"

#Define necessary variables
declare -A TOP_ARRAY
export LC_ALL=C

#Define functions
function makeOrAddToGroup() {
    TITLE=$(echo "$1")
    TYPE=$(echo "$2")
    OBJECT="{ \"title\" : \"$TITLE\", \"type\" : \"$TYPE\", \"values\" : [$3] }"
    if [[ "$4" != "" ]]
    then
        echo "$4,$OBJECT"
    else
        echo "$OBJECT"
    fi
}
function makeOrAddToValues() {
    TITLE=$(echo "$1")
    TYPE=$(echo "$2")
    VALUE=$(echo "$3")
    DISPLAY=$(echo "$4")
    OBJECT="{ \"title\" : \"$TITLE\" , \"type\" : \"$TYPE\" , \"value\" : \"$VALUE\" , \"display\" : \"$DISPLAY\" }"
    if [[ "$5" != "" ]]
    then
        echo "$5,$OBJECT"
    else
        echo "$OBJECT"
    fi
}

#Run curl command to get IP info
PUBLIC_IP=$(curl -sS -m 1 https://ipinfo.io/ip)

#Run hostname commands to get network info
HOSTNAME=$(hostname)
PRIVATE_IP=$(hostname -i)
FQDN=$(hostname -f)

#Run top command to get cpu & time info
TOP=$(top -b -n2 -d1 | grep "top -\|Task\|Cpu\|Mem\|Swap" | tail -5)
CPU=$(echo "$TOP" | head -n 3 | tail -n 1)
UPTIME=$(echo "$TOP" | head -1 | grep -oP '(?<=up ).*?,.*?,' | sed 's/:/ hours, /g' | sed -r 's/(.*),/\1 minutes/')

#Run ps command to get processes info
CPU_PROCESSES=$(ps axo "%p|%U|%C|" o "pmem" o "|%c|" o "rss" --sort=-pcpu | tr '\n' '#' | tr -d ' ' | sed -r 's/(.*)#/\1/')
MEM_PROCESSES=$(ps axo "%p|%U|%C|" o "pmem" o "|%c|" o "rss" --sort=-pmem | tr '\n' '#' | tr -d ' ' | sed -r 's/(.*)#/\1/')

#Run df command to get all disk info
DF=$(df -hT | awk '{print $1"|"$2"|"$3"|"$4"|"$5"|"$6"|"$7}' | tr '\n' '#' | sed 's/\\/\\\\/g')

#Run free command to get mem & swap info
FREE=$(free | tail -n 2)

#Run df command to get root disk info
DF_ROOT=$(df -PT / | tail -n 1)

#Run dd command to get write info
DD=$(dd if=/dev/zero of=/tmp/output bs=8k count=10k 2>&1 | tail -n 1; rm -f /tmp/output;);

#Parse /etc/passwd for user info
USERS=$(printf "USERNAME|UID|GID|FULL NAME|HOME#" && cat /etc/passwd | awk -F ':' '{print $1"|"$3"|"$4"|"$5"|"$6}' | tr '\n' '#')

#Parse /etc/group for group info
GRPS=$(printf "NAME|GID|USERS#" && cat /etc/group | awk -F ':' '{print $1"|"$3"|"$4}' | tr '\n' '#')

#Run last command to get last login info
LOGINS=$(printf "USER|IP|LOGIN - LOGOUT|LENGTH" && last -di | grep -v reboot | awk '{ printf $1"|"$3"|"; s = ""; for (i = 4; i <= NF; i++) s = s $i " "; print s }' | sed 's/ (/|/g' | tr -d ')' | sed '$d' | sed '$d' | tr '\n' '#')

#Run netstat or ss command to get connection info
NETSTAT=$(netstat &>/dev/null | sed 1d; echo $?);
SS=$(ss &>/dev/null | sed 1d; echo $?);
if [[ $NETSTAT == 0 ]]
then
    CONNECTIONS=$(netstat -tu --numeric-hosts | awk '/EST/{print $4"|"$5}')
elif [[ $SS == 0 ]]
then
    CONNECTIONS=$(ss -tu | awk '/EST/{print $5"|"$6}')
fi
CONNECTION_HEADER=$(printf "PORT|IP|ORG|CITY|REGION|COUNTRY|POSTAL#")
CONNECTION_INFO=$(printf "$CONNECTION_HEADER"; echo "$CONNECTIONS" | sed "s/$PRIVATE_IP://g" | grep -v "^127.\|^:" | grep -Po ".*(?=:)" | tr '\n' '#')


##Build json objects

#CPU
DATA=""

#CPU Used Chart
CPU_USED_PCENT=$(echo "$CPU" | awk -F ':' '{print $2}' | sed 's/[,%]/ /g' | awk '{print $7}' | awk '{printf "%0.1f", 100 - $1}')
TITLE="Used"
VALUE="$CPU_USED_PCENT"
TYPE="chart"
DISPLAY="$CPU_USED_PCENT%"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#CPU Name
TITLE="Name"
VALUE=$(cat /proc/cpuinfo | grep -i 'model name' | tr -d '\t' | tail -1 | sed 's/model name: //g')
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#CPU Cores
TITLE="Cores"
VALUE=$(nproc --all)
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#CPU Used
TITLE="Used"
VALUE="$CPU_USED_PCENT%"
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

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
VALUE="$MEM_USED_PCENT"
TYPE="chart"
DISPLAY="$MEM_USED GB ($MEM_USED_PCENT%)"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Memory Total
MEM_TOTAL=$(echo "$MEM" | awk -v v1=$CONVERT '{printf "%0.1f", $2 / v1}')
TITLE="Total"
VALUE="$MEM_TOTAL GB"
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Memory Used
TITLE="Used"
VALUE="$MEM_USED GB ($MEM_USED_PCENT%)"
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Memory Free
MEM_FREE=$(echo "$MEM" | awk -v v1=$CONVERT '{printf "%0.1f", $4 / v1}')
MEM_FREE_PCENT=$(echo "$MEM" | awk '{printf "%0.1f", $4 / $2 * 100}')
TITLE="Free"
VALUE="$MEM_FREE GB ($MEM_FREE_PCENT%)"
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Memory Cache
MEM_CACHE=$(echo "$MEM" | awk -v v1=$CONVERT '{printf "%0.1f", $6 / v1}')
MEM_CACHE_PCENT=$(echo "$MEM" | awk '{printf "%0.1f", $6 / $2 * 100}')
TITLE="Cache"
VALUE="$MEM_CACHE GB ($MEM_CACHE_PCENT%)"
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

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
VALUE="$SWAP_USED_PCENT"
TYPE="chart"
DISPLAY="$SWAP_USED GB ($SWAP_USED_PCENT%)"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Swap Total
SWAP_TOTAL=$(echo "$SWAP" | awk -v v1=$CONVERT '{printf "%0.1f", $2 / v1}')
TITLE="Total"
VALUE="$SWAP_TOTAL GB"
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Swap Used
TITLE="Used"
VALUE="$SWAP_USED GB ($SWAP_USED_PCENT%)"
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Swap Free
SWAP_FREE=$(echo "$SWAP" | awk -v v1=$CONVERT '{printf "%0.1f", $4 / v1}')
SWAP_FREE_PCENT=$(echo "$SWAP" | awk '{printf "%0.1f", $4 / $2 * 100}')
TITLE="Free"
VALUE="$SWAP_FREE GB ($SWAP_FREE_PCENT%)"
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Swap Group
TITLE="Swap"
TYPE="chart"
GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")


#CPU Processes
DATA=""

#CPU Process List
TITLE="CPU Processes"
VALUE="$CPU_PROCESSES"
TYPE="search"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#CPU Proccesses Group
TITLE="CPU Proccesses"
TYPE="search"
GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")


#MEM Processes
DATA=""

#MEM Process List
TITLE="MEM Processes"
VALUE="$MEM_PROCESSES"
TYPE="search"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#MEM Proccesses Group
TITLE="MEM Proccesses"
TYPE="search"
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
VALUE=$(cat /etc/*release | grep ^NAME= | awk -F '=' '{print $2}' | tr -d '"')
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#OS Version
TITLE="Version"
VALUE=$(cat /etc/*release | grep ^VERSION= | awk -F '=' '{print $2}' | tr -d '"')
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#OS Arch
TITLE="Arch"
VALUE=$(uname -m)
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#OS Group
TITLE="Operating System"
TYPE="text"
GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")


##Kernel
DATA=""

#Kernel Name
TITLE="Name"
VALUE=$(uname -s)
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Kernel Release
TITLE="Release"
VALUE=$(uname -r)
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Kernel Version
TITLE="Version"
VALUE=$(uname -v)
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Kernel Group
TITLE="Kernel"
TYPE="text"
GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")


##Time
DATA=""

#Time Name
TITLE="Server Time"
VALUE=$(date)
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Up Time
TITLE="Uptime"
VALUE="$UPTIME"
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Time Group
TITLE="Time"
TYPE="text"
GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")


##Users
DATA=""

#User List
TITLE="Users"
VALUE="$USERS"
TYPE="search"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Users Group
TITLE="Users"
TYPE="text"
GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")


##Groups
DATA=""

#Group List
TITLE="Groups"
VALUE="$GRPS"
TYPE="search"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Groups Group
TITLE="Groups"
TYPE="text"
GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")


##Logins
DATA=""

#Login List
TITLE="Logins"
VALUE="$LOGINS"
TYPE="search"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

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
VALUE="$HOSTNAME"
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Computer URL
TITLE="URL"
VALUE="$FQDN"
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Computer Public IP
TITLE="Public IP"
VALUE="$PUBLIC_IP"
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Computer Private IP
TITLE="Private IP"
VALUE="$PRIVATE_IP"
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Computer Location
# TITLE="Location"
# VALUE="$LOCATION"
# TYPE="detail"
# DISPLAY="$VALUE"
# DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Computer Group
TITLE="Computer"
TYPE="text"
GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")


##Connection
DATA=""

#Connection IP List
TITLE="IP List"
VALUE="${CONNECTION_INFO}7131|23.228.172.13|[client-request]#443|72.182.66.65|[hidden]#"
TYPE="search"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

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
VALUE="$DISK_ACTIVITY_PCENT"
TYPE="chart"
DISPLAY="$DISK_ACTIVITY_PCENT%"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Disk Type
TITLE="Type"
VALUE=$(echo "$DF_ROOT" | awk '{print $2}')
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Disk Total
DISK_TOTAL=$(echo "$DF_ROOT" | awk -v v1=$CONVERT '{printf "%0.1f", $3 / v1}')
TITLE="Total"
VALUE="$DISK_TOTAL GB"
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Disk Used
DISK_USED=$(echo "$DF_ROOT" | awk -v v1=$CONVERT '{printf "%0.1f", $4 / v1}')
DISK_USED_PCENT=$(echo "$DF_ROOT" | awk '{printf "%0.1f", $4 / $3 * 100}')
TITLE="Used"
VALUE="$DISK_USED GB ($DISK_USED_PCENT%)"
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Disk Free
DISK_FREE=$(echo "$DF_ROOT" | awk -v v1=$CONVERT '{printf "%0.1f", $5 / v1}')
DISK_FREE_PCENT=$(echo "$DF_ROOT" | awk '{printf "%0.1f", $5 / $3 * 100}')
TITLE="Free"
VALUE="$DISK_FREE GB ($DISK_FREE_PCENT%)"
TYPE="detail"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

# #Disk Write Speed
# DISK_WRITE_SPEED=$(echo "$DD" | awk -F ',' '{print $4}' | sed 's/^[ ]//')
# TITLE="Write Speed"
# VALUE="$DISK_WRITE_SPEED"
# TYPE="detail"
# DISPLAY="$VALUE"
# DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

#Disk Group
TITLE="Root Disk"
TYPE="chart"
GROUP=$(makeOrAddToGroup "$TITLE" "$TYPE" "$DATA" "$GROUP")


#Disk Partitions
DATA=""

#Disk Partitions List
TITLE="Disk Partitions"
VALUE="$DF"
TYPE="search"
DISPLAY="$VALUE"
DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$VALUE" "$DISPLAY" "$DATA")

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
#$JQ -Rn ".results |= $GROUP"
exit

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

RESULTS=$($JQ -s . <<< "$RESULTS")
$JQ -Rn ".results |= $RESULTS"
