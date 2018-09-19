# Mbed OS 5.9.x

Collection of debug utilities for Pelion Client workflow.

## mbed-os-blockdevice-erase

Short Mbed OS project that uses storage-selector and erases the selected BlockDevice.

### Compilation

Example compilation for K64F:

    cd mbed-os-blockdevice-erase
    mbed deploy
    mbed target K64F
    mbed toolchain GCC_ARM
    mbed compile

## mbed-os-blockdevice-dump

Short Mbed OS project that uses storage-selector and dumps the contents of the selected BlockDevice in IntelHex format to the debug log.

### Compilation

Example compilation for K64F:

    cd mbed-os-blockdevice-dump
    mbed deploy
    mbed target K64F
    mbed toolchain GCC_ARM
    mbed compile

### Filtering IntelHex from debug log

Valid IntelHex content can be parsed from the debug log with `grep` using the following arguments

    grep -P '^(?:\:02|\:00|\:10[0-9A-F]{4}00[0-9A-F]{34}$)' debug.log > debug.hex
    # Regular Expression explanation:
    # ^ - start of log line
    # (?:) - non matching RegEx group
    # \:02 - Line starts with :02
    # | - or
    # \:00 - Line starts with :00
    # | - or
    # \:10[0-9A-F]{4}00[0-9A-F]{34}$ - Line starts with :10, followed by 4 hexadecimals characters, followed by 00, followed by 34 hexadecimals characters and followed by a line end.

**Note:** If the debug log contains corrupted characters in the data lines, these lines won't be matched by the Regular Expression and the lines are ignored. This effectively leaves gaps to the hex-file.

## mbed-os-filesystem-reformat

Short Mbed OS project that uses storage-selector and reformats the BlockDevice with the chosen FileSystem.

### Compilation

Example compilation for K64F:

    cd mbed-os-filesystem-reformat
    mbed deploy
    mbed target K64F
    mbed toolchain GCC_ARM
    mbed compile
