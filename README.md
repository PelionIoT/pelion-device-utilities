# mbed Cloud Client preflight check
This repository contains scripts to help check mbed Cloud Client operation requirements.
## preflight.sh
This is the main test script to test mbed Cloud Client operation requirements. When executed, the script goes through basic test set and creates a log file to `./preflight.txt`. The log file contains all the executed commands and their output. The script halts execution on first error and needs to succeed without errors in order for mbed Cloud Client to work.

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

Following certificates and keys are checked during the preflight.sh. If matching pair exists, they are used to create a test connection to mbed Cloud.

| Filename                     | Description |
| ---------------------------- | ----------- |
| `mbed_cloud_dev_credentials.c` | If found, the C-file is parsed for device key and certificate and tested against mbed Cloud bootstrap server. NOTE: Parsing the C-file can be picky about the syntax. |
| `developer_cert.pem`           | If found, the certificate is tested against mbed Cloud bootstrap server. |
| `developer_key.pem`            | The private key for developer_cert.pem. |
| `bootstrap_cert.pem`           | If found, the certificate is tested against mbed Cloud bootstrap server. |
| `bootstrap_key.pem`            | The private key for bootstrap_cert.pem. |
| `lwm2m_cert.pem`               | If found, the certificate is tested against mbed Cloud LwM2M server. |
| `lwm2m_key.pem`                | The private key for lwm2m_cert.pem. |

## network.sh ##
This script is automatically executed as part of `preflight.sh` but it can also be executed manually. This is useful when a specific network needs to be tested for mbed Cloud connectivity.

Network test script can be run with:

    ./network.sh

## sysinfo.sh
Saves OS architecture and distribution information to `./sysinfo.txt` to help mbed Cloud Client porting and debugging.

System info script can be run with:

    ./sysinfo.sh
