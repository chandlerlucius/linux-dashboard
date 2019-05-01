#!/usr/bin/env bats

load ../../main/resources/sh/ServerStats

@test "Run makeOrAddToValues with one dataset" {
    #Test 1
    DATA=""
    TITLE="TEST TITLE 1"
    TYPE="TEST TYPE 1"
    THRESHOLD="TEST THRESHOLD 1"
    VALUE="TEST VALUE 1"

    run makeOrAddToValues "$TITLE" "$TYPE" "$THRESHOLD" "$VALUE" "$DATA"

    [ "$status" -eq 0 ]
    [ "$output" = "{ \"title\" : \"$TITLE\" , \"type\" : \"$TYPE\" , \"threshold\" : \"$THRESHOLD\" , \"value\" : \"$VALUE\" }" ]
}

@test "Run makeOrAddToValues with two datasets" {
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

    [ "$status" -eq 0 ]
    [ "$output" = "$DATA,{ \"title\" : \"$TITLE\" , \"type\" : \"$TYPE\" , \"threshold\" : \"$THRESHOLD\" , \"value\" : \"$VALUE\" }" ]
}