#!/usr/bin/env bats

. src/main/resources/sh/ServerStats.sh "TEST"

@test "Test Creating Values Array and JSON with 1 Dataset - makeOrAddToValues()" {
    #Test 1
    DATA=""
    TITLE="TEST TITLE 1"
    TYPE="TEST TYPE 1"
    THRESHOLD="TEST THRESHOLD 1"
    VALUE="TEST VALUE 1"

    run makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA"
    echo "$output" 

    [ "$status" -eq 0 ]
    [ "$output" = "{ \"title\" : \"$TITLE\" , \"type\" : \"$TYPE\" , \"threshold\" : \"$THRESHOLD\" , \"value\" : \"$VALUE\" }" ]
}

@test "Test Creating Values Array and JSON with 2 Datasets - makeOrAddToValues()" {
    #Test 1
    DATA=""
    TITLE="TEST TITLE 1"
    TYPE="TEST TYPE 1"
    THRESHOLD="TEST THRESHOLD 1"
    VALUE="TEST VALUE 1"
    DATA=$(makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA")

    #Test 2
    TITLE="TEST TITLE 2"
    TYPE="TEST TYPE 2"
    THRESHOLD="TEST THRESHOLD 2"
    VALUE="TEST VALUE 2"

    run makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA"
    echo "$output" 

    [ "$status" -eq 0 ]
    [ "$output" = "$DATA,{ \"title\" : \"$TITLE\" , \"type\" : \"$TYPE\" , \"threshold\" : \"$THRESHOLD\" , \"value\" : \"$VALUE\" }" ]
}

@test "Test Public IP Command - getPublicIP()" {
    run getPublicIP
    echo "$output" 

    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+$ ]]
}

@test "Test Private IP Command - getPrivateIP()" {
    run getPrivateIP
    echo "$output" 

    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+$ ]]
}

@test "Test Hostname Command - getHostname()" {
    run getHostname
    echo "$output" 

    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9a-z-]+$ ]]
}

@test "Test Top Command - getTop()" {
    run getTop
    echo "$output" 

    [ "$status" -eq 0 ]
    LINE=$(echo "$output" | sed '1q;d')
    [[ "$LINE" =~ ^top.+?[0-9]+[\ ](user|users),[\ ]+load[\ ]average:[\ ][0-9.]+,[\ ][0-9.]+,[\ ][0-9.]+$ ]]
    LINE=$(echo "$output" | sed '2q;d')
    [[ "$LINE" =~ ^Tasks:.+?[0-9]+.+?total,.+?[0-9]+.+?running,.+?[0-9]+.+?sleeping,.+?[0-9]+.+?stopped,.+?[0-9]+.+?zombie$ ]]
    LINE=$(echo "$output" | sed '3q;d')
    [[ "$LINE" =~ ^%Cpu\(s\):[\ ]*[0-9.]+[\ ]us,[\ ]*[0-9.]+[\ ]sy,[\ ]*[0-9.]+[\ ]ni,[\ ]*[0-9.]+[\ ]id,[\ ]*[0-9.]+[\ ]wa,[\ ]*[0-9.]+[\ ]hi,[\ ]*[0-9.]+[\ ]si,[\ ]*[0-9.]+[\ ]st$ ]]
}

@test "Test Uptime Command - getUptime()" {
    run getUptime
    echo "$output" 

    [ "$status" -eq 0 ]
    [[ "$output" =~ ^up.+?minute[s]*$ ]]
}