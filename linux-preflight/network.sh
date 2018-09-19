#!/bin/sh
# Copyright 2018 ARM Ltd.

# Load common variables and functions
#  - defines LWM2M_SERVER
#  - defines BOOTSTRAP_SERVER
. ./common.sh

test_port()
{
    # Check that netcat is available
    if [ ! `command -v nc` ]; then
        echo "Missing nc, cannot test \"$@\" reachability"
        return 0
    fi

    # Check that "-z" option from netcat is available.
    # - "-z" feels to be more portable way of testing ports than using </dev/null.
    local Z_OPTION_AVAILABLE="true"
    if [ "`nc -z 2>&1 | grep 'invalid option'`" ]; then
        Z_OPTION_AVAILABLE="false"
    fi

    # Test
    echo "Test ping to \"$@\" with netcat:"
    if [ "$1" = "TCP" ] && [ "$Z_OPTION_AVAILABLE" = "true" ]; then
        nc -zv "$2" "$3"
        # -z   - test port (not always available)
        # -v   - verbose

    elif [ "$1" = "TCP" ]; then
        # piping /dev/null to stdin causes immediate disconnection with TCP in many implementations
        nc -v "$2" "$3" </dev/null

    elif [ "$1" = "UDP" ] && [ "$Z_OPTION_AVAILABLE" = "true" ]; then
        nc -uzv -w3 "$2" "$3"
        # -u   - UDP (wait ICMP message back)
        # -z   - test port
        # -v   - verbose
        # -w3  - timeout after 3 seconds

    elif [ "$1" = "UDP" ]; then
        echo "Missing nc with -z option, cannot test \"$@\" reachability"
        return 0

    else
        echo "test_port(), select UDP or TCP, not \"$1\""
        return 1
    fi

    echo "success"
    return 0
}

# Test DNS lookup
echo "Test DNS lookup:"
if [ `command -v nslookup` ]; then
    nslookup "$LWM2M_SERVER"
    nslookup "$BOOTSTRAP_SERVER"
else
    echo "Missing nslookup, cannot test DNS lookup."
fi
echo "success"
divider

# Test ping Pelion servers
echo "Test ping to Pelion servers:"
if [ `command -v ping` ]; then
    ping -c 3 "$LWM2M_SERVER"
    ping -c 3 "$BOOTSTRAP_SERVER"
else
    echo "Missing ping, cannot test ping to Pelion."
fi
echo "success"
divider

# Loop through network ports from "network_ports.csv"
while read destination; do
    # Skip lines that don't start with UDP or TCP
    #  - Not using case fallthrough because of portability
    case "$destination" in
        UDP* )
            test_port $destination
        ;;
        TCP* )
            test_port $destination
        ;;
    esac
done < "network_ports.csv"
divider

# Test update download
echo "Test update download:"
DOWNLOAD_URL="https://s3.amazonaws.com/mbed-customer-engineering/test.file"
DOWNLOAD_FILE="./cache/preflight_testbinary.bin"
if [ `command -v wget` ]; then
    wget --version
    echo "wget \"$DOWNLOAD_URL\""
    measure_time wget "$DOWNLOAD_URL" --no-check-certificate --output-document "$DOWNLOAD_FILE"
elif [ `command -v curl` ]; then
    curl --version
    echo "curl \"$DOWNLOAD_URL\""
    measure_time curl "$DOWNLOAD_URL" --insecure --output "$DOWNLOAD_FILE"
else
    echo "Missing wget and curl, cannot verify network download."
fi
divider

# Check download integrity
echo "Check download integrity:"
if [ `command -v sha256sum` ] && [ -e "$DOWNLOAD_FILE" ]; then
    echo "sha256sum"
    sha256sum -c "preflight_testbinary.sha256"
elif [ `command -v md5sum` ]; then
    echo "md5sum"
    md5sum -c "preflight_testbinary.md5"
else
    echo "Missing sha256sum and md5sum, cannot verify download integrity."
fi
divider

# Delete downloaded file
rm -f "$DOWNLOAD_FILE"
