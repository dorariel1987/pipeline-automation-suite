#!/usr/bin/env bats

setup() {
    LIB="${BATS_TEST_DIRNAME}/../lib"
}

@test "vault::render_secret produces a valid Secret manifest" {
    run bash -c "
        source ${LIB}/vault-helpers.sh
        printf 'A=alpha\nB=beta\n' | vault::render_secret my-secret default
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"kind: Secret"* ]]
    [[ "$output" == *"name: my-secret"* ]]
    [[ "$output" == *"namespace: default"* ]]
    # alpha base64 → YWxwaGE=  ;  beta base64 → YmV0YQ==
    [[ "$output" == *"A: YWxwaGE="* ]]
    [[ "$output" == *"B: YmV0YQ=="* ]]
}

@test "vault::render_secret skips empty lines" {
    run bash -c "
        source ${LIB}/vault-helpers.sh
        printf '\nA=1\n\n' | vault::render_secret s ns
    "
    [ "$status" -eq 0 ]
    line_count=$(echo "$output" | grep -c "^  [A-Z]")
    [ "$line_count" -eq 1 ]
}
