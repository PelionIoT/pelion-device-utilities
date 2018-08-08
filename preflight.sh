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
        #  1. remove all newlines
        #  2. convert every ";" to newline
        #  3. select variable of intrest ($2)
        #  4. select everything inside {}
        #  5. remove all ", 0x"
        #  6. reverse convert from hex string to binary
        cat $1 | \
            tr -d "\n" | \
            tr ";" "\n" | \
            sed -n "/$2\[\]/p" | \
            sed -nr 's/.*\{(.*)\}/\1/p' | \
            sed 's/,* *0x//g' | \
            xxd -r -ps > "$3"
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
    if [ `command -v dd` ]; then
        echo "Test entropy generation:"
        echo "In some simulated environments entropy generation can be really slow."
        echo "This can slow down or even hang mbed Cloud Client startup."
        dd --version
        time dd if=/dev/random of=/dev/null bs=512 count=10 iflag=fullblock
        divider
    fi


    # ===============
    # Test network
    # ===============
    # Test DNS lookup
    LWM2M_SERVER="lwm2m.us-east-1.mbedcloud.com"
    BOOTSTRAP_SERVER="bootstrap.us-east-1.mbedcloud.com"
    if [ `command -v nslookup` ]; then
        echo "Test DNS lookup:"
        nslookup "$LWM2M_SERVER"
        nslookup "$BOOTSTRAP_SERVER"
        divider
    fi

    # Test ping mbed Cloud servers
    if [ `command -v ping` ]; then
        echo "Test ping mbed Cloud servers:"
        ping -c 3 "$LWM2M_SERVER"
        ping -c 3 "$BOOTSTRAP_SERVER"
        divider
    fi

    # Test TCP network ports
    if [ `command -v nc` ]; then
        echo "Test TCP network ports:"
        # LwM2M connection
        nc -v "$LWM2M_SERVER" 5684  </dev/null

        # Bootstrap connection
        nc -v "$BOOTSTRAP_SERVER" 5684  </dev/null
        divider
    fi

    # Test update download
    TEST_FILE="https://s3.amazonaws.com/mbed-customer-engineering/test.file"
    if [ `command -v wget` ]; then
        echo "Test update download:"
        wget --version
        time wget "$TEST_FILE" --output-document "preflight_testbinary.bin"
        divider
    elif [ `command -v curl` ]; then
        echo "Test update download:"
        curl --version
        time curl "$TEST_FILE" --output "preflight_testbinary.bin"
        divider
    fi

    # Check download integrity
    if [ `command -v sha256sum` ]; then
        echo "Check download integrity:"
        sha256sum -c "preflight_testbinary.sha256"
        divider
    fi

    # Delete downloaded file
    rm -f "preflight_testbinary.bin"


    # =================
    # Test certificates
    # =================
    if [ `command -v openssl` ]; then
        openssl version
    fi

    # Check mbed_cloud_dev_credentials.c
    if [ `command -v sed` ] && \
       [ `command -v xxd` ] && \
       [ `command -v expect` ] && \
       [ `command -v openssl` ] && \
       [ -e "mbed_cloud_dev_credentials.c" ]
    then
        echo "Test mbed_cloud_dev_credentials.c:"
        echo "Warning: parsing C-files into arrays can be unreliable at times."
        # Parse bootstrap CA certificate
        parse_mbed_cloud_dev_credentials_c_array "mbed_cloud_dev_credentials.c" \
            MBED_CLOUD_DEV_BOOTSTRAP_SERVER_ROOT_CA_CERTIFICATE "certificates/parsed_bootstrap_ca.der"

        # Parse device certificate and key from mbed_cloud_dev_credentials.c
        parse_mbed_cloud_dev_credentials_c_array "mbed_cloud_dev_credentials.c" \
            MBED_CLOUD_DEV_BOOTSTRAP_DEVICE_CERTIFICATE "parsed_developer_cert.der"

        parse_mbed_cloud_dev_credentials_c_array "mbed_cloud_dev_credentials.c" \
            MBED_CLOUD_DEV_BOOTSTRAP_DEVICE_PRIVATE_KEY "parsed_developer_key.der"

        # Convert key and certificates to PEM
        openssl pkey -in "parsed_developer_key.der" -inform der -out "parsed_developer_key.pem"
        openssl x509 -in "parsed_developer_cert.der" -inform der -out "parsed_developer_cert.pem"
        openssl x509 -in "certificates/parsed_bootstrap_ca.der" -inform der -out "certificates/parsed_bootstrap_ca.pem"

        # Test connection using mbed_cloud_dev_credentials.c
        expect "test_certificate.exp" "$BOOTSTRAP_SERVER:5684" \
            "certificates/parsed_bootstrap_ca.pem" \
            "parsed_developer_cert.pem" \
            "parsed_developer_key.pem"
        divider
    fi

    # Check developer certificate
    if [ `command -v expect` ] && \
       [ `command -v openssl` ] && \
       [ -e "developer_cert.pem" ] && \
       [ -e "developer_key.pem" ]
    then
        echo "Test developer certificate:"
        expect "test_certificate.exp" "$BOOTSTRAP_SERVER:5684" \
            "certificates/bootstrap_ca.pem" \
            "developer_cert.pem" \
            "developer_key.pem"
        divider
    fi

    # Check bootstrap certificate
    if [ `command -v expect` ] && \
       [ `command -v openssl` ] && \
       [ -e "bootstrap_cert.pem" ] && \
       [ -e "bootstrap_key.pem" ]
    then
        echo "Test bootstrap certificate:"
        expect "test_certificate.exp" "$BOOTSTRAP_SERVER:5684" \
            "certificates/bootstrap_ca.pem" \
            "bootstrap_cert.pem" \
            "bootstrap_key.pem"
        divider
    fi

    # Check LwM2M certificate
    if [ `command -v expect` ] && \
       [ `command -v openssl` ] && \
       [ -e "lwm2m_cert.pem" ] && \
       [ -e "lwm2m_key.pem" ]
    then
        echo "Test LwM2M certificate:"
        expect "test_certificate.exp" "$LWM2M_SERVER:5684" \
            "certificates/lwm2m_ca.pem" \
            "lwm2m_cert.pem" \
            "lwm2m_key.pem"
        divider
    fi
} | tee "$REPORT_FILE" 2>&1
