#!/bin/sh

#Define all basic variables
convert_b_to_gb=1048576
one_second_in_millis=$((1 * 1000))
two_seconds_in_millis=$((2 * 1000))
ten_minutes_in_millis=$((1 * 1000 * 60 * 10))
seconds_to_keep=60

#Set function name from script parameter
function_name="$*"

#Commands and Urls
#SSL_CHECK_URL="https://api.ssllabs.com/api/v3/analyze?host=$HOST_URL&publish=off&ignoreMismatch=on&all=done"

#Define necessary variables
export LC_ALL=C

#Define common functions
groups() {
    cpu_name=$(lscpu | grep -i "^model name" | sed 's/^.*:[ ]*//')
    echo "{ \"groups\" : [ " \
         "    { \"id\" : \"status\" , \"title\" : \"Status\" , " \
         "    \"subgroups\" : [ " \
         "        { \"id\" : \"cpu\" , \"title\" : \"CPU\" , \"type\" : \"chart\" , \"subtitle\" : \"$cpu_name\" , " \
         "        \"properties\" : [ " \
         "            { \"id\" : \"cpu_usage\" , \"type\" : \"chart\" , \"interval\" : $two_seconds_in_millis } , " \
         "            { \"id\" : \"cpu_processes\" , \"type\" : \"detail\" , \"interval\" : $one_second_in_millis  } , " \
         "            { \"id\" : \"cpu_threads\" , \"type\" : \"detail\" , \"interval\" : $one_second_in_millis  } , " \
         "            { \"id\" : \"cpu_speed\" , \"type\" : \"detail\" , \"interval\" : $one_second_in_millis  } , " \
         "            { \"id\" : \"cpu_sockets\" , \"type\" : \"detail\" , \"interval\" : $ten_minutes_in_millis  } , " \
         "            { \"id\" : \"cpu_cores\" , \"type\" : \"detail\" , \"interval\" : $ten_minutes_in_millis  } , " \
         "            { \"id\" : \"cpu_processors\" , \"type\" : \"detail\" , \"interval\" : $ten_minutes_in_millis  } " \
         "        ] } , " \
         "        { \"id\" : \"memory\" , \"title\" : \"Memory\" , \"type\" : \"chart\" , " \
         "        \"properties\" : [ " \
         "            { \"id\" : \"mem_usage\" , \"type\" : \"chart\" , \"interval\" : $two_seconds_in_millis } , " \
         "            { \"id\" : \"mem_total\" , \"type\" : \"detail\" , \"interval\" : $one_second_in_millis  } , " \
         "            { \"id\" : \"mem_used\" , \"type\" : \"detail\" , \"interval\" : $one_second_in_millis  } , " \
         "            { \"id\" : \"mem_free\" , \"type\" : \"detail\" , \"interval\" : $one_second_in_millis  } , " \
         "            { \"id\" : \"mem_cache\" , \"type\" : \"detail\" , \"interval\" : $one_second_in_millis  } " \
         "        ] } , " \
         "        { \"id\" : \"disk\" , \"title\" : \"Disk\" , \"type\" : \"chart\" , " \
         "        \"properties\" : [ " \
         "            { \"id\" : \"disk_usage\" , \"type\" : \"chart\" , \"interval\" : $two_seconds_in_millis } , " \
         "            { \"id\" : \"disk_total\" , \"type\" : \"detail\" , \"interval\" : $one_second_in_millis  } , " \
         "            { \"id\" : \"disk_used\" , \"type\" : \"detail\" , \"interval\" : $one_second_in_millis  } , " \
         "            { \"id\" : \"disk_free\" , \"type\" : \"detail\" , \"interval\" : $one_second_in_millis  } , " \
         "            { \"id\" : \"disk_mount\" , \"type\" : \"detail\" , \"interval\" : $ten_minutes_in_millis  } , " \
         "            { \"id\" : \"disk_filesystem\" , \"type\" : \"detail\" , \"interval\" : $ten_minutes_in_millis  } , " \
         "            { \"id\" : \"disk_type\" , \"type\" : \"detail\" , \"interval\" : $ten_minutes_in_millis  } , " \
         "            { \"id\" : \"disk_model\" , \"type\" : \"detail\" , \"interval\" : $ten_minutes_in_millis  } " \
         "        ] } , " \
         "        { \"id\" : \"swap\" , \"title\" : \"Swap\" , \"type\" : \"chart\" , " \
         "        \"properties\" : [ " \
         "            { \"id\" : \"swap_usage\" , \"type\" : \"chart\" , \"interval\" : $two_seconds_in_millis  } , " \
         "            { \"id\" : \"swap_total\" , \"type\" : \"detail\" , \"interval\" : $one_second_in_millis  } , " \
         "            { \"id\" : \"swap_used\" , \"type\" : \"detail\" , \"interval\" : $one_second_in_millis  } , " \
         "            { \"id\" : \"swap_free\" , \"type\" : \"detail\" , \"interval\" : $one_second_in_millis  } , " \
         "            { \"id\" : \"swap_cache\" , \"type\" : \"detail\" , \"interval\" : $one_second_in_millis  } " \
         "        ] } " \
         "    ] } , " \
         "    { \"id\" : \"general\" , \"title\" : \"General Info\" , " \
         "    \"subgroups\" : [ " \
         "        { \"id\" : \"os\" , \"title\" : \"Operating System\" , \"type\" : \"detail\" , " \
         "        \"properties\" : [ " \
         "            { \"id\" : \"os_name\" , \"type\" : \"detail\" , \"interval\" : $ten_minutes_in_millis  } , " \
         "            { \"id\" : \"os_version\" , \"type\" : \"detail\" , \"interval\" : $ten_minutes_in_millis  } , " \
         "            { \"id\" : \"os_arch\" , \"type\" : \"detail\" , \"interval\" : $ten_minutes_in_millis  } " \
         "        ] } , " \
         "        { \"id\" : \"kernel\" , \"title\" : \"Kernel\" , \"type\" : \"detail\" , " \
         "        \"properties\" : [ " \
         "            { \"id\" : \"kernel_name\" , \"type\" : \"detail\" , \"interval\" : $ten_minutes_in_millis  } , " \
         "            { \"id\" : \"kernel_version\" , \"type\" : \"detail\" , \"interval\" : $ten_minutes_in_millis  } , " \
         "            { \"id\" : \"kernel_arch\" , \"type\" : \"detail\" , \"interval\" : $ten_minutes_in_millis  } " \
         "        ] } , " \
         "        { \"id\" : \"time\" , \"title\" : \"Time\" , \"type\" : \"detail\" , " \
         "        \"properties\" : [ " \
         "            { \"id\" : \"server_time\" , \"type\" : \"detail\" , \"interval\" : $one_second_in_millis  } , " \
         "            { \"id\" : \"up_time\" , \"type\" : \"detail\" , \"interval\" : $one_second_in_millis  } " \
         "        ] } " \
         "    ] }  " \
         "] }"
}

create_json() {
    id="$1"
    title="$2"
    type="$3"
    threshold="$4"
    interval="$5"
    value="$6"
    echo "{ \"id\" : \"$id\" , \"title\" : \"$title\" , \"type\" : \"$type\" , \"threshold\" : \"$threshold\" , \"interval\" : $interval , \"value\" : \"$value\" }"
}

create_json_non_string_value() {
    id="$1"
    title="$2"
    type="$3"
    threshold="$4"
    interval="$5"
    value="$6"
    echo "{ \"id\" : \"$id\" , \"title\" : \"$title\" , \"type\" : \"$type\" , \"threshold\" : \"$threshold\" , \"interval\" : $interval , \"value\" : $value }"
}

cpu_name() {
    id="$function_name"
    title="Name"
    type="detail"
    threshold=""
    interval=$one_second_in_millis
    value=$(lscpu | grep -i "^model name" | sed 's/^.*:[ ]*//')
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

cpu_usage_file="/tmp/cpu-usage.txt"
update_cpu_usage() {
    seconds=$(date '+%s')
    date=$(date '+%H:%M:%S')
    current_usage="$seconds $date "$(top -b -n2 -p1 -d1 | grep "Cpu(s)" | tail -1 | awk -F ':' '{print $2}' | sed 's/[,%]/ /g' | awk '{print $7}' | awk '{printf " %0.1f", 100 - $1}')
    if [ ! -f "$cpu_usage_file" ]
    then
        echo "$current_usage" > "/tmp/bad_${seconds}.txt"
        echo "$current_usage" > "$cpu_usage_file"
    else 
        echo "$current_usage" >> "$cpu_usage_file"
        data_to_keep=$(sort -u -k1,1 "$cpu_usage_file" | tail -${seconds_to_keep})
        data_lines=$(echo "$data_to_keep" | wc -l)
        if [ "$data_lines" -ge $seconds_to_keep ]
        then
            echo "$data_to_keep" > "$cpu_usage_file"
        else 
            echo "$data_to_keep" > "/tmp/no_${seconds}.txt"
        fi
    fi
}

cpu_usage() {
    update_cpu_usage
    id="$function_name"
    title="Usage"
    type="chart"
    threshold="85"
    interval=$one_second_in_millis
    value1=$(printf "["; awk '{print $2}' "$cpu_usage_file" | sed -e "s/\(.*\)/\"\1\"/" | tr '\n' ',' | sed 's/.$//'; printf "]");
    value2=$(printf "["; awk '{print $3}' "$cpu_usage_file" | tr '\n' ',' | sed 's/.$//'; printf "]")
    create_json_non_string_value "$id" "$title" "$type" "$threshold" "$interval" "[ $value1 , $value2 ]"
}

cpu_processes() {
    id="$function_name"
    title="Processes"
    type="detail"
    threshold=""
    interval=$one_second_in_millis
    value=$(ps -A --no-headers | wc -l)
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

cpu_threads() {
    id="$function_name"
    title="Threads"
    type="detail"
    threshold=""
    interval=$one_second_in_millis
    value=$(ps -eo nlwp --no-headers | awk '{ sum += $1 } END { print sum }')
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

cpu_handles() {
    id="$function_name"
    title="Handles"
    type="detail"
    threshold=""
    interval=$one_second_in_millis
    value=$(lsof -n | wc -l)
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

cpu_speed() {
    id="$function_name"
    title="Speed"
    type="detail"
    threshold=""
    interval=$one_second_in_millis
    value=$(lscpu | grep -i "^cpu mhz" | sed 's/^.*:[ ]*//' | awk '{print $1 / 1000 " Ghz"}')
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

cpu_sockets() {
    id="$function_name"
    title="Sockets"
    type="detail"
    threshold=""
    interval=$ten_minutes_in_millis
    value=$(lscpu | grep -i "^socket(s)" | sed 's/^.*:[ ]*//')
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

cpu_cores() {
    id="$function_name"
    title="Cores"
    type="detail"
    threshold=""
    interval=$ten_minutes_in_millis
    value=$(lscpu | grep -i "^core(s)" | sed 's/^.*:[ ]*//')
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

cpu_processors() {
    id="$function_name"
    title="Processors"
    type="detail"
    threshold=""
    interval=$ten_minutes_in_millis
    value=$(lscpu | grep -i "^cpu(s)" | sed 's/^.*:[ ]*//')
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

mem_usage_file="/tmp/mem-usage.txt"
update_mem_usage() {
    date=$(date '+%Y-%m-%d_%H:%M:%S')
    current_usage="$date "$(free | tail -2 | grep -i "mem" | awk '{printf "%0.1f", $3 / $2 * 100}')
    if [ ! -f "$mem_usage_file" ] || [ ! -s "$mem_usage_file" ]
    then
        echo "$current_usage" > "$mem_usage_file"
    fi
    sed -i "1i$current_usage" "$mem_usage_file"
    sed -i "$seconds_to_keep"',$d' "$mem_usage_file"
}

mem_usage() {
    update_mem_usage
    id="$function_name"
    title="Usage"
    type="chart"
    threshold="85"
    interval=$one_second_in_millis
    value1=$(printf "["; sort < "$mem_usage_file" | awk '{print $1}' | sed -e "s/.*_\(.*\)/\"\1\"/" | tr '\n' ',' | sed 's/.$//'; printf "]");
    value2=$(printf "["; sort < "$mem_usage_file" | awk '{print $2}' | tr '\n' ',' | sed 's/.$//'; printf "]")
    create_json_non_string_value "$id" "$title" "$type" "$threshold" "$interval" "[ $value1 , $value2 ]"
}

mem_total() {
    id="$function_name"
    title="Total"
    type="detail"
    threshold="85"
    interval=$one_second_in_millis
    value=$(free | tail -2 | grep -i "mem" | awk -v v1=$convert_b_to_gb '{printf "%0.1f", $2 / v1}')
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

mem_used() {
    id="$function_name"
    title="Used"
    type="detail"
    threshold="85"
    interval=$one_second_in_millis
    value=$(free | tail -2 | grep -i "mem" | awk -v v1=$convert_b_to_gb '{printf "%0.1f GB (%0.0f%%)", $3 / v1, $3 / $2 * 100}')
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

mem_free() {
    id="$function_name"
    title="Free"
    type="detail"
    threshold="85"
    interval=$one_second_in_millis
    value=$(free | tail -2 | grep -i "mem" | awk -v v1=$convert_b_to_gb '{printf "%0.1f GB (%0.0f%%)", $4 / v1, $4 / $2 * 100}')
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

mem_cache() {
    id="$function_name"
    title="Cache"
    type="detail"
    threshold="85"
    interval=$one_second_in_millis
    value=$(free | tail -2 | grep -i "mem" | awk -v v1=$convert_b_to_gb '{printf "%0.1f GB (%0.0f%%)", $6 / v1, $6 / $2 * 100}')
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

disk_usage_file="/tmp/disk-usage.txt"
update_disk_usage() {
    date=$(date '+%Y-%m-%d_%H:%M:%S')
    current_usage="$date "$(diff=0; total_1=0; total_2=0; start_millis=$(date +%s%3N); while read -r line; do current=$(echo "$line" | awk '{print $13}'); total_1=$((total_1 + current)); done < /proc/diskstats; sleep 1.0; while read -r line; do current=$(echo "$line" | awk '{print $13}'); total_2=$((total_2 + current)); done < /proc/diskstats; end_millis=$(date +%s%3N); diff=$((total_2 - total_1)); elapsed_millis=$((end_millis - start_millis)); awk -v x=$diff -v y=$elapsed_millis 'BEGIN { printf "%0.2f", x / y * 100}';)
    if [ ! -f "$disk_usage_file" ] || [ ! -s "$disk_usage_file" ]
    then
        echo "$current_usage" > "$disk_usage_file"
    fi
    sed -i "1i$current_usage" "$disk_usage_file"
    sed -i "$seconds_to_keep"',$d' "$disk_usage_file"
}

disk_usage() {
    update_disk_usage
    id="$function_name"
    title="Usage"
    type="chart"
    threshold="85"
    interval=$one_second_in_millis
    value1=$(printf "["; sort < "$disk_usage_file" | awk '{print $1}' | sed -e "s/.*_\(.*\)/\"\1\"/" | tr '\n' ',' | sed 's/.$//'; printf "]");
    value2=$(printf "["; sort < "$disk_usage_file" | awk '{print $2}' | tr '\n' ',' | sed 's/.$//'; printf "]")
    create_json_non_string_value "$id" "$title" "$type" "$threshold" "$interval" "[ $value1 , $value2 ]"
}

disk_total() {
    id="$function_name"
    title="Total"
    type="detail"
    threshold=""
    interval=$one_second_in_millis
    value=$(df -PT / | tail -1 | awk -v v1=$convert_b_to_gb '{printf "%0.1f GB", $3 / v1}')
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

disk_used() {
    id="$function_name"
    title="Used"
    type="detail"
    threshold=""
    interval=$one_second_in_millis
    value=$(df -PT / | tail -1 | awk -v v1=$convert_b_to_gb '{printf "%0.1f GB (%0.0f%%)", $4 / v1, $4 / $3 * 100}')
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

disk_free() {
    id="$function_name"
    title="Free"
    type="detail"
    threshold=""
    interval=$one_second_in_millis
    value=$(df -PT / | tail -1 | awk -v v1=$convert_b_to_gb '{printf "%0.1f GB (%0.0f%%)", $5 / v1, $5 / $3 * 100}')
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

disk_mount() {
    id="$function_name"
    title="Mount Point"
    type="detail"
    threshold=""
    interval=$ten_minutes_in_millis
    value="/"
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

disk_filesystem() {
    id="$function_name"
    title="File System"
    type="detail"
    threshold=""
    interval=$ten_minutes_in_millis
    value=$(df -PT / | tail -1 | awk '{print $2}')
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

disk_type() {
    id="$function_name"
    title="Type"
    type="detail"
    threshold=""
    interval=$ten_minutes_in_millis
    value=$(file_system=$(df -PT / | tail -1 | awk '{print $1}'); lsblk -lp -o "TYPE" "$file_system" | tail -1)
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

disk_model() {
    id="$function_name"
    title="Model"
    type="detail"
    threshold=""
    interval=$ten_minutes_in_millis
    name=$(lsblk -lp -o "NAME,VENDOR" | grep -P "(^/dev/[s|v]da) " | sed 's/\/dev\/[s|v]da//g')
    vendor=$(lsblk -lp -o "NAME,MODEL" | grep -P "(^/dev/[s|v]da) " | sed 's/\/dev\/[s|v]da//g')
    value="$name - $vendor"
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

cpu_load() {
    id="$function_name"
    title="CPU Load"
    type="detail"
    threshold=""
    interval=$one_second_in_millis
    value="cpu_load"
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

swap_usage_file="/tmp/swap-usage.txt"
update_swap_usage() {
    date=$(date '+%Y-%m-%d_%H:%M:%S')
    current_usage="$date "$(free | tail -2 | grep -i "swap" | awk '{printf "%0.1f", $3 / $2 * 100}')
    if [ ! -f "$swap_usage_file" ] || [ ! -s "$swap_usage_file" ]
    then
        echo "$current_usage" > "$swap_usage_file"
    fi
    sed -i "1i$current_usage" "$swap_usage_file"
    sed -i "$seconds_to_keep"',$d' "$swap_usage_file"
}

swap_usage() {
    update_swap_usage
    id="$function_name"
    title="Usage"
    type="chart"
    threshold="85"
    interval=$one_second_in_millis
    value1=$(printf "["; sort < "$swap_usage_file" | awk '{print $1}' | sed -e "s/.*_\(.*\)/\"\1\"/" | tr '\n' ',' | sed 's/.$//'; printf "]");
    value2=$(printf "["; sort < "$swap_usage_file" | awk '{print $2}' | tr '\n' ',' | sed 's/.$//'; printf "]")
    create_json_non_string_value "$id" "$title" "$type" "$threshold" "$interval" "[ $value1 , $value2 ]"
}

swap_total() {
    id="$function_name"
    title="Total"
    type="detail"
    threshold="85"
    interval=$one_second_in_millis
    value=$(free | tail -n 2 | grep -i "swap" | awk -v v1=$convert_b_to_gb '{printf "%0.1f", $2 / v1}')
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

swap_used() {
    id="$function_name"
    title="Used"
    type="detail"
    threshold="85"
    interval=$one_second_in_millis
    value=$(free | tail -n 2 | grep -i "swap" | awk -v v1=1048576 '{printf "%0.1f GB (%0.0f%%)", $3 / v1, $3 / $2 * 100}')
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

swap_free() {
    id="$function_name"
    title="Free"
    type="detail"
    threshold="85"
    interval=$one_second_in_millis
    value=$(free | tail -n 2 | grep -i "swap" | awk -v v1=$convert_b_to_gb '{printf "%0.1f GB (%0.0f%%)", $4 / v1, $4 / $2 * 100}')
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

swap_cache() {
    id="$function_name"
    title="Cache"
    type="detail"
    threshold="85"
    interval=$one_second_in_millis
    value=$(free | tail -n 2 | grep -i "swap" | awk -v v1=$convert_b_to_gb '{printf "%0.1f GB (%0.0f%%)", $6 / v1, $6 / $2 * 100}')
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

os_name() {
    id="$function_name"
    title="Name"
    type="detail"
    threshold=""
    interval=$ten_minutes_in_millis
    value=$(cat /etc/*release | grep ^NAME= | awk -F '=' '{print $2}' | tr -d '"')
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

os_version() {
    id="$function_name"
    title="Version"
    type="detail"
    threshold=""
    interval=$ten_minutes_in_millis
    value=$(cat /etc/*release | grep ^VERSION= | awk -F '=' '{print $2}' | tr -d '"')
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

os_arch() {
    id="$function_name"
    title="Arch"
    type="detail"
    threshold=""
    interval=$ten_minutes_in_millis
    value=$(uname -m)
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

kernel_name() {
    id="$function_name"
    title="Name"
    type="detail"
    threshold=""
    interval=$ten_minutes_in_millis
    value=$(uname -s)
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

kernel_version() {
    id="$function_name"
    title="Version"
    type="detail"
    threshold=""
    interval=$ten_minutes_in_millis
    value=$(uname -r)
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

kernel_arch() {
    id="$function_name"
    title="Arch"
    type="detail"
    threshold=""
    interval=$ten_minutes_in_millis
    value=$(uname -v)
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

server_time() {
    id="$function_name"
    title="Server Time"
    type="detail"
    threshold=""
    interval=$one_second_in_millis
    value=$(date)
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

up_time() {
    id="$function_name"
    title="Up Time"
    type="detail"
    threshold=""
    interval=$one_second_in_millis
    value=$(up_time_raw)
    create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
}

up_time_raw() {
    uptime -p
}

getCPUProcesses() {
    top -b -n2 -d0.1 -o %CPU | awk '/^top/{i++}i==2' | tail -n +7 | awk '{print $1"|"$2"|"$9"|"$10"|"$12"|"$11}' | tr '\n' '#'
}

getMEMProcesses() {
    ps axo "%p|%U|%C|" o "pmem" o "|%c|" o "rss" --sort=-pmem | tr '\n' '#' | tr -d ' ' | sed -r 's/(.*)#/\1/'
}

getUsers() {
    printf "USERNAME|UID|GID|FULL NAME|HOME#" && sort -g -t : -k 3 /etc/passwd | awk -F ':' '{print $1"|"$3"|"$4"|"$5"|"$6}' | tr '\n' '#'
}

getGrps() {
    printf "NAME|GID|USERS#" && sort -g -t : -k 3 /etc/group | awk -F ':' '{print $1"|"$3"|"$4}' | tr '\n' '#'
}

getLogins() {
    printf "USER|IP|LOGIN - LOGOUT|LENGTH#" && last -di | grep -v reboot | awk '{ printf $1"|"$3"|"; s = ""; for (i = 4; i <= NF; i++) s = s $i " "; print s }' | sed 's/ (/|/g' | tr -d ')' | sed '$d' | sed '$d' | tr '\n' '#'
}

getHostname() {
    hostname
}

getPublicIP() {
    # curl --max-time 1 --connect-time 1 https://ipapi.co/ip
    echo "test"
}

getPrivateIP() {
    hostname -I | awk '{print $1}'
}

getConnections() {
    NETSTAT=$(netstat >/dev/null 2>&1 | sed 1d; echo $?);
    SS=$(ss >/dev/null 2>&1 | sed 1d; echo $?);
    if [ "$NETSTAT" -eq 0 ]
    then
        CONNECTIONS=$(netstat -tun | awk '/EST/{print $4"|"$5}')
    elif [ "$SS" -eq 0 ]
    then
        CONNECTIONS=$(ss -tun | awk '/EST/{print $5"|"$6}')
    fi
    CONNECTION_HEADER=$(printf "PORT|IP|ORG|CITY|REGION|COUNTRY|POSTAL#")
    printf "%s" "$CONNECTION_HEADER"; echo "$CONNECTIONS" | grep -v "^127.\\|^:" | grep -Po ".*(?=:)" | tr '\n' '#'
    # echo "test"
}

getDiskPartitions() {
    df -hT | awk '{print $1"|"$2"|"$3"|"$4"|"$5"|"$6"|"$7}' | tr '\n' '#' | sed 's/\\/\//g'
}

help() {
    grep "^.*()" "$0" | grep -v "help"
}

if [ "_$1" = "_" ]
then
    help
else
    "$function_name"
fi