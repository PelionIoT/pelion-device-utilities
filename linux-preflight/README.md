# Pelion preflight check
This folder contains test scripts to check Pelion Device Management Client or Pelion Edge operation requirements on Unix-like operating system.

## preflight.sh
This is the main test script for Pelion preflight check. When executed, the script goes through set of tests and creates a log file to `./preflight.txt`. The log file contains all the executed commands and their output. The script halts execution on the first error and needs to succeed without any errors in order for mbed Cloud Client or mbed Edge to work.

Preflight test script can be run with:

    ./preflight.sh

**Tested features:**

* File creation
* Folder creation
* Entropy generation from /dev/random
* Network
    * TCP port
    * UDP port
    * Update download & integrity
* Certificates
    * Developer certificates
	    * mbed\_cloud\_dev\_credentials.c
	    * developer\_cert.pem & developer\_key.pem
    * Bootstrap certificates
	    * bootstrap\_cert.pem & bootstrap\_key.pem
    * Direct LwM2M certificates (BYOC - Bring Your Own Certificate)
	    * lwm2m\_cert.pem & lwm2m\_key.pem

Following certificates and keys are checked during the preflight.sh. If matching pair exists, they are used to create a test connection to Pelion.

| Filename                     | Description |
| ---------------------------- | ----------- |
| `mbed_cloud_dev_credentials.c` | If found, the C-file is parsed for device key and certificate and tested against Pelion bootstrap server. NOTE: Parsing the C-file can be picky about the syntax. |
| `developer_cert.pem`           | If found, the certificate is tested against Pelion bootstrap server. |
| `developer_key.pem`            | The private key for developer_cert.pem. |
| `bootstrap_cert.pem`           | If found, the certificate is tested against Pelion bootstrap server. |
| `bootstrap_key.pem`            | The private key for bootstrap_cert.pem. |
| `lwm2m_cert.pem`               | If found, the certificate is tested against Pelion LwM2M server. |
| `lwm2m_key.pem`                | The private key for lwm2m_cert.pem. |

## network.sh
This script is automatically executed as part of `preflight.sh` but it can also be executed manually. This is useful when a specific network needs to be tested for Pelion connectivity.

The network test script can be ran with:

    ./network.sh

## sysinfo.sh
This script is automatically executed as part of `preflight.sh` but it can also be executed manually. This can be useful when extracting information from the current platform.

The system info script can be ran with:

    ./sysinfo.sh

## Transferring preflight script to the Device-Under-Test
A makefile is provided within the project to tar archive all the important files and convert it to Base64 encoded string. This string then can be pasted through terminal for easy transfer to the DUT (Device-Under-Test).

### Compressed (recommended)
The package Base64 string can be created with:

    make base64

The Base64 string can be received on the DUT side with following command:

    mkdir preflight
    cd preflight
    base64 -d | tar -xzf -
    # paste full Base64 string
    # send enter
    # send EOF with ctrl+d
    # the tar archive is now extracted to the current directory

### Uncompressed
In case the DUT doesn't have ability to extract compressed tar archives, a larger uncompressed version can be used:

    make base64_uncompressed

The uncompressed Base64 string can be received on the DUT with following command:

    mkdir preflight
    cd preflight
    base64 -d | tar -xf -
    # pase full Base64 string
    # send enter
    # send EOF with ctrl+x
    # the tar archive is now extracted to the current directory

### Tar archives
Plain tar archives can be created with:

    make tar
    # or
    make tar_uncompressed
