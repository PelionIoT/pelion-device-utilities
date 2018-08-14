#!/bin/sh
# Copyright 2018 ARM Ltd.

# Load common variables and functions
#  - defines LWM2M_SERVER
#  - defines BOOTSTRAP_SERVER
. ./common.sh

test_tcp_port()
{
    echo "Testing TCP connection to $1:$2"
    if [ ! `command -v nc` ]; then
        echo "Missing nc, cannot test TCP port reachability"
        return 0
    fi
    # Netcat can be used to test TCP connection to a remote port.
    # In this test script, the connection should terminate immediately after
    # successful connection. This can be achieved with "-z" test flag or by
    # piping "</dev/null" to stdin.

    # If nc has "-z" test option available, use it because piping "</dev/null"
    # to stdin in some implementations doesn't cause immediate disconnection.
    if [ ! "`nc -z 2>&1 | grep 'invalid option'`" ]; then
        nc -zv "$1" "$2"
        # -z   - test port (not always available)
        # -v   - verbose
    else
        nc -v "$1" "$2" </dev/null
    fi
    echo "success"
    divider
    return 0
}

test_udp_port()
{
    echo "Testing UDP connection to $1:$2"
    if [ ! `command -v nc` ] || [ "`nc -z 2>&1 | grep 'invalid option'`" ]; then
        echo "Missing nc with -z option, cannot test UDP port reachability"
        return 0
    fi

    nc -uzv -w3 "$1" "$2"
    # -u   - UDP (wait ICMP message back)
    # -z   - test port
    # -v   - verbose
    # -w3  - timeout after 3 seconds
    echo "success"
    divider
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
divider

# Test ping Pelion servers
echo "Test ping Pelion servers:"
if [ `command -v ping` ]; then
    ping -c 3 "$LWM2M_SERVER"
    ping -c 3 "$BOOTSTRAP_SERVER"
else
    echo "Missing ping, cannot test ping to Pelion."
fi
divider

# Test TCP network ports
test_tcp_port "$LWM2M_SERVER" 5684
test_tcp_port "$BOOTSTRAP_SERVER" 5684

# Test UDP network ports
test_udp_port "$LWM2M_SERVER" 5684
test_udp_port "$BOOTSTRAP_SERVER" 5684

# Test update download
echo "Test update download:"
TEST_FILE="https://s3.amazonaws.com/mbed-customer-engineering/test.file"
if [ `command -v wget` ]; then
    wget --version
    measure_time wget "$TEST_FILE" --no-check-certificate --output-document "preflight_testbinary.bin"
elif [ `command -v curl` ]; then
    curl --version
    measure_time curl "$TEST_FILE" --insecure --output "preflight_testbinary.bin"
else
    echo "Missing wget and curl, cannot verify network download."
fi
divider

# Check download integrity
echo "Check download integrity:"
if [ `command -v sha256sum` ] && [ -e "preflight_testbinary.bin" ]; then
    sha256sum -c "preflight_testbinary.sha256"
elif [ `command -v md5sum` ]; then
    md5sum -c "preflight_testbinary.md5"
else
    echo "Missing sha256sum and md5sum, cannot verify download integrity."
fi
divider

# Delete downloaded file
rm -f "preflight_testbinary.bin"