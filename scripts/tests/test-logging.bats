#!/usr/bin/env bats

setup() {
    LIB="${BATS_TEST_DIRNAME}/../lib"
}

@test "log::info writes timestamped INFO line to stderr" {
    run bash -c "source ${LIB}/logging.sh && log::info hello 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" == *"[INFO ]"* ]]
    [[ "$output" == *"hello"* ]]
}

@test "log::debug is silenced when LOG_LEVEL is not debug" {
    run bash -c "source ${LIB}/logging.sh && log::debug secret 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" != *"secret"* ]]
}

@test "log::debug prints when LOG_LEVEL=debug" {
    run bash -c "LOG_LEVEL=debug; source ${LIB}/logging.sh && log::debug visible 2>&1"
    [ "$status" -eq 0 ]
    [[ "$output" == *"visible"* ]]
}

@test "log::fatal exits non-zero" {
    run bash -c "source ${LIB}/logging.sh && log::fatal boom"
    [ "$status" -eq 1 ]
}

@test "require_cmd fails for missing binary" {
    run bash -c "source ${LIB}/logging.sh && require_cmd definitely-not-a-real-binary-xyz"
    [ "$status" -eq 1 ]
}

@test "require_env fails for empty variable" {
    run bash -c "source ${LIB}/logging.sh && unset MY_VAR && require_env MY_VAR"
    [ "$status" -eq 1 ]
}

@test "require_env passes for non-empty variable" {
    run bash -c "source ${LIB}/logging.sh && export MY_VAR=ok && require_env MY_VAR"
    [ "$status" -eq 0 ]
}
