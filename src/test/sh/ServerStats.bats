#!/usr/bin/env bats

. src/main/resources/sh/ServerStats.sh > /dev/null

@test "Test creating JSON array with string value - create_json()" {
    id="Test ID"
    title="Test Title"
    type="Test Type"
    threshold="Test Threshold"
    interval=10
    value="10"

    run create_json "$id" "$title" "$type" "$threshold" "$interval" "$value"
    echo "$output" 

    [ "$status" -eq 0 ]
    [ "$output" = "{ \"id\" : \"$id\" , \"title\" : \"$title\" , \"type\" : \"$type\" , \"threshold\" : \"$threshold\" , \"interval\" : $interval , \"value\" : \"$value\" }" ]
}

@test "Test creating JSON array with non string value - create_json_non_string_value()" {
    id="Test ID"
    title="Test Title"
    type="Test Type"
    threshold="Test Threshold"
    interval=10
    value=10

    run create_json_non_string_value "$id" "$title" "$type" "$threshold" "$interval" "$value"
    echo "$output" 

    [ "$status" -eq 0 ]
    [ "$output" = "{ \"id\" : \"$id\" , \"title\" : \"$title\" , \"type\" : \"$type\" , \"threshold\" : \"$threshold\" , \"interval\" : $interval , \"value\" : $value }" ]
}

@test "Test uptime - up_time_raw()" {
    run up_time_raw
    echo "$output" 

    [ "$status" -eq 0 ]
    [[ "$output" =~ ^up.+?minute[s]*$ ]]
}