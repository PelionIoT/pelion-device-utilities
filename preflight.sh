#!/bin/sh
# Copyright 2018 ARM Ltd.

if [ ! `command -v tee` ]; then
    echo "It seems this system doesn't have command \"tee\" available."
    echo "\"tee\" is used for logging only and it can be replaced with \"cat\" from the last line of this script."
    exit 1
fi

REPORT_FILE="./preflight.txt"
{
    divider()
    {
        set +x
        echo "---------------\n"
        set -x
    }

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
        printf "$ARRAY_DATA" > "$3"
    }

    test_certificate()
    {
        # Check openssl
        if [ ! `command -v openssl` ]; then
            echo "Missing openssl, cannot verify \"$3\" certificate."
            return 0
        fi

        # Don't check certificate if it doesn't exist
        if [ ! -e "$3" ] || [ ! -e "$4" ]; then
            return 0
        fi

        # All good continue testing
        echo "Test \"$3\" certificate:"

        # Don't stop on openssl error, we need to print more info
        set +e

        # Try open secure channel to given server
        openssl s_client -debug -connect "$1" \
            -CAfile "$2" \
            -cert "$3" \
            -key "$4" \
            -verify_return_error </dev/null
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

    # Stop on error
    set -e

    # Print all commands
    set -x

    # =====================
    # Test file permissions
    # =====================
    # File creation
    echo "Test file permissions:"
    touch preflight_testfile.txt
    rm preflight_testfile.txt
    echo "success"
    divider

    # Folder creation
    echo "Folder creation:"
    mkdir preflight_testfolder
    rmdir preflight_testfolder
    echo "success"
    divider


    # =======================
    # Test entropy generation
    # =======================
    echo "Test entropy generation:"
    echo "In some simulated environments entropy generation can be really slow."
    echo "This can slow down or even hang mbed Cloud Client startup."
    if [ `command -v dd` ]; then
        # busybox dd --version returns non-zero value -> "|| :"
        dd --version || :
        # Not using "iflag=fullblock" as it is not available in all "dd" implementations.
        # This can be worked around with size set to 1 and count to 512.
        echo "Start gathering entropy... (if the test hangs here, it means that entropy generation is slow)"
        dd if=/dev/random of=/dev/null bs=1 count=512
    else
        echo "Missing dd, cannot test entropy generation speed."
    fi
    divider


    # ===============
    # Test network
    # ===============
    LWM2M_SERVER="lwm2m.us-east-1.mbedcloud.com"
    BOOTSTRAP_SERVER="bootstrap.us-east-1.mbedcloud.com"

    # Test DNS lookup
    echo "Test DNS lookup:"
    if [ `command -v nslookup` ]; then
        nslookup "$LWM2M_SERVER"
        nslookup "$BOOTSTRAP_SERVER"
    else
        echo "Missing nslookup, cannot test DNS lookup."
    fi
    divider

    # Test ping mbed Cloud servers
    echo "Test ping mbed Cloud servers:"
    if [ `command -v ping` ]; then
        ping -c 3 "$LWM2M_SERVER"
        ping -c 3 "$BOOTSTRAP_SERVER"
    else
        echo "Missing ping, cannot test ping to mbed Cloud."
    fi
    divider

    # Test TCP network ports
    echo "Test TCP network ports:"
    if [ `command -v nc` ]; then
        nc -v "$LWM2M_SERVER" 5684  </dev/null
        nc -v "$BOOTSTRAP_SERVER" 5684  </dev/null
    else
        echo "Missing nc, cannot test mbed Cloud port reachability."
    fi
    divider

    # Test update download
    echo "Test update download:"
    TEST_FILE="https://s3.amazonaws.com/mbed-customer-engineering/test.file"
    if [ `command -v wget` ]; then
        wget --version
        time wget "$TEST_FILE" --no-check-certificate --output-document "preflight_testbinary.bin"
    elif [ `command -v curl` ]; then
        curl --version
        time curl "$TEST_FILE" --insecure --output "preflight_testbinary.bin"
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


    # =================
    # Test certificates
    # =================
    if [ `command -v openssl` ]; then
        openssl version
    else
        echo "Missing openssl, cannot verify certificates."
    fi

    # Check mbed_cloud_dev_credentials.c
    if [ `command -v sed` ] && \
       [ `command -v printf` ] && \
       [ `command -v openssl` ] && \
       [ -e "mbed_cloud_dev_credentials.c" ]
    then
        echo "Test mbed_cloud_dev_credentials.c:"
        echo "Warning: parsing C-files into arrays can be unreliable at times."
        # Parse bootstrap CA certificate
        parse_mbed_cloud_dev_credentials_c_array "mbed_cloud_dev_credentials.c" \
            MBED_CLOUD_DEV_BOOTSTRAP_SERVER_ROOT_CA_CERTIFICATE "parsed_bootstrap_ca.der"

        # Parse device certificate and key from mbed_cloud_dev_credentials.c
        parse_mbed_cloud_dev_credentials_c_array "mbed_cloud_dev_credentials.c" \
            MBED_CLOUD_DEV_BOOTSTRAP_DEVICE_CERTIFICATE "parsed_developer_cert.der"

        parse_mbed_cloud_dev_credentials_c_array "mbed_cloud_dev_credentials.c" \
            MBED_CLOUD_DEV_BOOTSTRAP_DEVICE_PRIVATE_KEY "parsed_developer_key.der"

        # Convert key and certificates to PEM
        openssl pkey -in "parsed_developer_key.der" -inform der -out "parsed_developer_key.pem"
        openssl x509 -in "parsed_developer_cert.der" -inform der -out "parsed_developer_cert.pem"
        openssl x509 -in "parsed_bootstrap_ca.der" -inform der -out "parsed_bootstrap_ca.pem"

        # Test mbed_cloud_dev_credentials.c certificate
        test_certificate "$BOOTSTRAP_SERVER:5684" "parsed_bootstrap_ca.pem" "parsed_developer_cert.pem" "parsed_developer_key.pem"

        # Delete parsed certificates
        rm "parsed_bootstrap_ca.der" "parsed_developer_cert.der" "parsed_developer_key.der"
        rm "parsed_bootstrap_ca.pem" "parsed_developer_cert.pem" "parsed_developer_key.pem"
    else
        echo "Missing sed, xxd or openssl, cannot verify mbed_cloud_dev_credentials.c."
    fi

    # Check developer certificate
    test_certificate "$BOOTSTRAP_SERVER:5684" "certificates/bootstrap_ca.pem" "developer_cert.pem" "developer_key.pem"

    # Check bootstrap certificate
    test_certificate "$BOOTSTRAP_SERVER:5684" "certificates/bootstrap_ca.pem" "bootstrap_cert.pem" "bootstrap_key.pem"

    # Check LwM2M certificate
    test_certificate "$LWM2M_SERVER:5684" "certificates/lwm2m_ca.pem" "lwm2m_cert.pem" "lwm2m_key.pem"

    # The script didn't exit, all good
    echo "All tests succeeded!"
} 2>&1 | tee "$REPORT_FILE"
