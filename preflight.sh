#!/bin/sh
# Copyright 2018 ARM Ltd.

# Load common variables and functions
#  - defines LWM2M_SERVER
#  - defines BOOTSTRAP_SERVER
. ./common.sh

if [ ! `command -v tee` ]; then
    echo "It seems this system doesn't have command \"tee\" available."
    echo "\"tee\" is used for logging only and it can be replaced with \"cat\" from the last line of this script."
    exit 1
fi

REPORT_FILE="./preflight.txt"
{
    parse_mbed_cloud_dev_credentials_c_array()
    {
        # Used to parse C arrays from "mbed_cloud_dev_credentials.c"
        #  1. tr -d "\n"                  - remove all newlines
        #  2. tr ";" "\n"                 - convert every ";" to newline
        #  3. sed -n "/$2\[\]/p"          - select line/variable of intrest ($2)
        #  4. sed -nr 's/.*\{(.*)\}/\1/p' - select everything inside {}
        #  5. sed 's/0x//g'               - remove every "0x"
        #  6. tr -d ", "                  - remove every "," and " "
        #  7. sed 's/../\\x&/g'           - prefix every byte with \x (required for hex print)
        local ARRAY_DATA=$(cat $1 | \
            tr -d "\n" | \
            tr ";" "\n" | \
            sed -n "/$2\[\]/p" | \
            sed -nr 's/.*\{(.*)\}/\1/p' | \
            sed 's/0x//g' | \
            tr -d ", " | \
            sed 's/../\\x&/g')

        # Write DER file to a file
        # Explicitly don't use the shell builtin printf. For example,
        # Ubuntu 16.04's sh builtin printf doesn't seem to want to print \xXX formatted hex data.
        $(which printf) "$ARRAY_DATA" > "$3"
    }

    test_certificate()
    {
        # Tests given certificate with handshake against Pelion servers.
        #  $1 = "TLS" / "DTLS"
        #  $2 = destination:port
        #  $3 = CAfile
        #  $4 = Certificate
        #  $5 = Private key

        # Don't check certificate if it doesn't exist
        if [ ! -e "$4" ] || [ ! -e "$5" ]; then
            return 0
        fi

        # All good continue testing
        echo "Test \"$4\" certificate:"

        # Don't stop on openssl error, we need to print more info
        set +e

        # Try open secure channel to given server
        if [ "$1" = "TLS" ]; then
            echo "TLS"
            openssl s_client -debug -connect "$2" \
                -CAfile "$3" \
                -cert "$4" \
                -key "$5" \
                -verify_return_error </dev/null
        elif [ "$1" = "DTLS" ]; then
            echo "DTLS"
            openssl s_client -dtls -debug -connect "$2" \
                -CAfile "$3" \
                -cert "$4" \
                -key "$5" \
                -verify_return_error </dev/null
        else
            echo "Select either \"TLS\" or \"DTLS\""
            return 1
        fi
        # piping /dev/null to stdin causes EOF being sent
        local OPENSSL_RETVAL=$?

        # Stop on error
        set -e

        # Check openssl return value
        if [ $OPENSSL_RETVAL -ne 0 ]; then
            echo "openssl failed with $OPENSSL_RETVAL, possibly invalid certificate?"
            return 1
        fi
        echo "success"
        divider
        return 0
    }

    available_openssl()
    {
        # Check if openssl exists
        if [ ! "`command -v openssl`" ]; then
            echo "Missing openssl, cannot verify certificates."
            return 1
        fi

        return 0
    }

    available_openssl_with_dtls()
    {
        # Check if openssl exists
        if ! available_openssl; then
            return 1
        fi

        # Check if openssl s_client -dtls option is available
        if [ ! "`openssl s_client -dtls 2>&1 | grep CONNECTED`" ]; then
            return 1
        fi

        return 0
    }

    # ====================
    # Generate sysinfo.txt
    # ====================
    ./sysinfo.sh

    # =====================
    # Test file permissions
    # =====================
    # File creation
    echo "Test file permissions:"
    echo "touch preflight_testfile.txt"
    touch preflight_testfile.txt
    rm preflight_testfile.txt
    echo "success"
    divider

    # Folder creation
    echo "Test folder creation:"
    echo "mkdir preflight_testfolder"
    mkdir preflight_testfolder
    echo "rmdir preflight_testfolder"
    rmdir preflight_testfolder
    echo "success"
    divider


    # =======================
    # Test entropy generation
    # =======================
    echo "Test entropy generation:"
    echo "Print entropy pool size"
    if [ -e "/proc/sys/kernel/random/" ]; then
        echo 'find "/proc/sys/kernel/random/"'
        find "/proc/sys/kernel/random/" -type f -exec sh -c "echo {}:; cat {}" \;
        echo
    fi

    if [ `command -v dd` ]; then
        # Not using "iflag=fullblock" as it is not available in all "dd" implementations.
        # This can be worked around with size set to 1 and count to 512.
        extra_info_start
        echo "In some simulated environments entropy generation can be really slow."
        echo "This can slow down or even hang mbed Cloud Client startup."
        echo
        echo "Below dd command tries to read 512 bytes from /dev/random. If the test"
        echo "hangs here, it means that entropy generation is slow. In debian based"
        echo "distributions, installing rng-tools with \"apt-get install rng-tools\""
        echo "usually increases entropy generation."
        extra_info_stop
        # Timing the opeartion as not all dd implementations print speed.
        echo "dd if=/dev/random of=/dev/null bs=1 count=512"
        measure_time dd if=/dev/random of=/dev/null bs=1 count=512
    else
        echo "Missing dd, cannot test entropy generation speed."
    fi
    divider


    # ===============
    # Test network
    # ===============
    # Network tests can be executed separately without dependency to other mbed Cloud Client requirements.
    echo "Test network connectivity:"
    extra_info_start
    echo "Network connection is required for Pelion device operation. TCP and UDP selection"
    echo "can be configured to mbed Cloud Client."
    echo
    echo "If network tests fail, it most likely means that there is a firewall configuration"
    echo "preventing the creation of a new outside network connection."
    extra_info_stop
    echo "./network.sh"
    ./network.sh


    # =================
    # Test certificates
    # =================
    echo "Test certificates:"
    if [ ! `command -v openssl` ]; then
        echo "Missing openssl, cannot verify certificates."
    fi

    # Check mbed_cloud_dev_credentials.c
    if [ `command -v sed` ] && \
       [ `command -v printf` ] && \
       [ -e "mbed_cloud_dev_credentials.c" ]
    then
        echo "Test mbed_cloud_dev_credentials.c:"
        extra_info_start
        echo "Warning: Parsing arrays from C-files can be very picky about the syntax."
        echo "If an certificate error is suspected to be in mbed_cloud_dev_credential.c,"
        echo "it is recommended to use a hex editor to cross reference the parsed der files"
        echo "with the byte-arrays found from the mbed_cloud_dev_credential.c."
        extra_info_stop
        # Parse bootstrap CA certificate
        parse_mbed_cloud_dev_credentials_c_array "mbed_cloud_dev_credentials.c" \
            MBED_CLOUD_DEV_BOOTSTRAP_SERVER_ROOT_CA_CERTIFICATE "./cache/parsed_bootstrap_ca.der"

        # Parse device certificate and key from mbed_cloud_dev_credentials.c
        parse_mbed_cloud_dev_credentials_c_array "mbed_cloud_dev_credentials.c" \
            MBED_CLOUD_DEV_BOOTSTRAP_DEVICE_CERTIFICATE "./cache/parsed_developer_cert.der"

        parse_mbed_cloud_dev_credentials_c_array "mbed_cloud_dev_credentials.c" \
            MBED_CLOUD_DEV_BOOTSTRAP_DEVICE_PRIVATE_KEY "./cache/parsed_developer_key.der"

        # Convert key and certificates to PEM
        set -x
        openssl pkey -in "./cache/parsed_developer_key.der"  -inform der -out "./cache/parsed_developer_key.pem"
        openssl x509 -in "./cache/parsed_developer_cert.der" -inform der -out "./cache/parsed_developer_cert.pem"
        openssl x509 -in "./cache/parsed_bootstrap_ca.der"   -inform der -out "./cache/parsed_bootstrap_ca.pem"
        set +x
    else
        echo "Missing sed, printf or the certificate, cannot verify mbed_cloud_dev_credentials.c."
    fi

    # Check certificates with TLS
    echo "Test TLS Handshake:"
    if available_openssl; then
        test_certificate "TLS" "$BOOTSTRAP_SERVER:5684" "./cache/parsed_bootstrap_ca.pem" "./cache/parsed_developer_cert.pem" "./cache/parsed_developer_key.pem"
        test_certificate "TLS" "$BOOTSTRAP_SERVER:5684" "./certificates/bootstrap_ca.pem" "./developer_cert.pem"              "./developer_key.pem"
        test_certificate "TLS" "$BOOTSTRAP_SERVER:5684" "./certificates/bootstrap_ca.pem" "./bootstrap_cert.pem"              "./bootstrap_key.pem"
        test_certificate "TLS" "$LWM2M_SERVER:5684"     "./certificates/lwm2m_ca.pem"     "./lwm2m_cert.pem"                  "./lwm2m_key.pem"
    fi

    # Check certificates with DTLS (openssl with -dtls)
    echo "Test DTLS Handshake:"
    if available_openssl_with_dtls; then
        test_certificate "DTLS" "$BOOTSTRAP_SERVER:5684" "./cache/parsed_bootstrap_ca.pem" "./cache/parsed_developer_cert.pem" "./cache/parsed_developer_key.pem"
        test_certificate "DTLS" "$BOOTSTRAP_SERVER:5684" "./certificates/bootstrap_ca.pem" "./developer_cert.pem"              "./developer_key.pem"
        test_certificate "DTLS" "$BOOTSTRAP_SERVER:5684" "./certificates/bootstrap_ca.pem" "./bootstrap_cert.pem"              "./bootstrap_key.pem"
        test_certificate "DTLS" "$LWM2M_SERVER:5684"     "./certificates/lwm2m_ca.pem"     "./lwm2m_cert.pem"                  "./lwm2m_key.pem"
    fi

    # The script didn't exit, all good
    echo "All tests succeeded!"
} 2>&1 | tee "$REPORT_FILE"
