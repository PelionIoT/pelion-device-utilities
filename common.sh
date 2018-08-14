#!/bin/sh
# Copyright 2018 ARM Ltd.

LWM2M_SERVER="lwm2m.us-east-1.mbedcloud.com"
BOOTSTRAP_SERVER="bootstrap.us-east-1.mbedcloud.com"

divider()
{
    set +x
    echo "---------------\n"
    set -x
}

measure_time()
{
    # Prefer using time (not always available)
    if [ `command -v time` ]; then
        time $@
    # Date can be also used for low precision measurements
    elif [ `command -v date` ] && [ "`date --version 2>&1 | grep GNU`" ]; then
        local START=$(date +%s)
        $@ # execute given commands
        local END=$(date +%s)
        local DIFF=$(expr $END - $START)
        echo "Duration:$DIFF s"
    else
        echo "Cannot print execution time as \"time\" and \"date\" are unavailable"
        $@ # execute without measuring
    fi
}

# Stop on error
set -e

# Print all commands
set -x
