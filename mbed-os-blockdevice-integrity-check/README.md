# mbed-os-blockdevice-integrity-check

Short Mbed OS project that uses storage-selector and writes a predefined pattern to the storage, then verify if the data being read back  from the storage are identical to what are  expected to have been written to it.

## Compilation

Example compilation for K64F:

    cd mbed-os-blockdevice-integrity-check
    mbed deploy
    mbed target K64F
    mbed toolchain GCC_ARM
    mbed compile

## Example Output

    --- Mbed OS block device integrity check ---
    --- Block device geometry ---
    read_size:    512 B
    program_size: 512 B
    erase_size:   512 B
    size:         15590227968 B
    ---
    Performing full storage test.
    
    Progressing...100.000%  |
    
    RESULT: all content identical.
    --- done! ---
