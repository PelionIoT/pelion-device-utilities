# mbed-os-blockdevice-info

Short Mbed OS project that uses BlockDevice::get_default_instance() to select a BlockDevice and prints info on it.

## Compilation

Example compilation for K64F:

    cd mbed-os-blockdevice-info
    mbed deploy
    mbed target K64F
    mbed toolchain GCC_ARM
    mbed compile

## Example Output
Baudrate is configured as 115200.

    init() = 0
    size() = 15523119104
    get_read_size() = 512
    get_program_size() = 512
    get_erase_size() = 512
    get_erase_value() = random
    deinit() = 0
