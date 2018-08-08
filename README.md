# mbed Cloud Client preflight check
This repository contains scripts to help check mbed Cloud Client opeartion requirements.
## preflight.sh
Checks file permissions, entropy generation, network connectivity and certificates and stores a report file to `./preflight.txt`. The script halts execution on first error and should succeed without any errors in order for mbed Cloud Client to work.

Following certificates and keys are checked during the preflight.sh. If matching pair exists, they are used to create a test connection to mbed Cloud.

| Filename                     | Description |
| ---------------------------- | ----------- |
| `mbed_cloud_dev_credentials.c` | If found, the C-file is parsed for device key and certificate and tested against mbed Cloud bootstrap server. NOTE: Plarsing the C-file can be picky about the syntax. |
| `developer_cert.pem`           | If found, the certificate is tested against mbed Cloud bootstrap server. |
| `developer_key.pem`            | The private key for developer_cert.pem. |
| `bootstrap_cert.pem`           | If found, the certificate is tested against mbed Cloud bootstrap server. |
| `bootstrap_key.pem`            | The private key for bootstrap_cert.pem. |
| `lwm2m_cert.pem`               | If found, the certificate is tested against mbed Cloud LwM2M server. |
| `lwm2m_key.pem`                | The private key for lwm2m_cert.pem. |

## sysinfo.sh
Saves OS architecture and distribution information to ./sysinfo.txt to help mbed Cloud Client porting and debugging.
