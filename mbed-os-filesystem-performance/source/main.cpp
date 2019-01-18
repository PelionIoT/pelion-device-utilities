/*
 * ----------------------------------------------------------------------------
 * Copyright 2018 ARM Ltd.
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ----------------------------------------------------------------------------
 */

#include "mbed.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <inttypes.h>
#include "BlockDevice.h"
#include "FileSystem.h"
#include "LittleFileSystem.h"

void generate_random(uint8_t *buf, ssize_t size) {
    //printf("generate_random()\n");
    for (ssize_t i=0; i<size; i++) {
        buf[i] = (uint8_t)rand();
    }
}

char* format_bytes(double amount) {
    size_t output_size = 11;
    char *output = (char*)malloc(output_size);

    // NOTE: double cannot fit all these
    const char postfixes[9][4] = {"B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB"};

    // Figure out exponent
    int exponent = 0;
    for (; amount > 1000.0; amount /= 1024.0) {
        exponent ++;
    }

    snprintf(output, output_size, "%.2f %s", amount, postfixes[exponent]);
    return output;
}

float do_write_test(FileSystem *fs, unsigned int seed, ssize_t test_size_in_bytes, ssize_t blocksize) {
    //printf("do_write_test(%d)\n", test_size_in_bytes);
    Timer t;
    int retval;
    uint8_t *buf = (uint8_t*)malloc(blocksize);

    // Open file
    const char *fname = "/default/mbed-os-filesystem-performance.tmp";
    FILE *fid = fopen(fname, "w+");
    if (fid == NULL) {
        printf("write file open failed\n");
        return -1;
    }

    // Test write
    srand(seed);
    t.start();
    float rand_duration = 0.0;
    for (ssize_t offset=0; offset < test_size_in_bytes; offset += blocksize) {
        // Could be a speed limitation
        float rand_start = t.read();
        generate_random(buf, blocksize);
        rand_duration += rand_start - t.read();

        // Write
        for (ssize_t block_offset=0; block_offset < blocksize;) {
            //ssize_t written = fs->file_write(file, buf + block_offset, blocksize - block_offset);
            int written = fwrite(buf + block_offset, sizeof(uint8_t), blocksize - block_offset, fid);
            block_offset += written;
        }
    }

    // Close file
    retval = fclose(fid);
    if (retval != 0) {
        printf("write file close failed%d\n", retval);
        return -1;
    }

    // NO SYNC???
    //fsync(fid);
    //fs->file_sync(file);
    t.stop();
    free(buf);
    return t.read() - rand_duration;
}

float do_read_test(FileSystem *fs, unsigned int seed, ssize_t test_size_in_bytes, ssize_t blocksize) {
    //printf("do_read_test()\n");
    Timer t;
    int retval;
    uint8_t *ref_buf = (uint8_t*)malloc((size_t)blocksize);
    uint8_t *read_buf = (uint8_t*)malloc((size_t)blocksize);

    // Open file
    const char *fname = "/default/mbed-os-filesystem-performance.tmp";
    FILE *fid = fopen(fname, "r");
    if (fid == NULL) {
        printf("read file open failed\n");
        return -1;
    }

    // Test read
    srand(seed);
    fseek(fid, 0, SEEK_SET);
    t.start();
    for (ssize_t offset=0; offset < test_size_in_bytes; offset += blocksize) {
        //printf("loop %d\n", offset);
        // Read
        for (ssize_t block_offset=0; block_offset < blocksize;) {
            //ssize_t read = fs->file_read(file, read_buf + block_offset, blocksize - block_offset);
            int read = fread(read_buf + block_offset, sizeof(uint8_t), blocksize - block_offset, fid);
            if (read == 0) {
                printf("fread() = 0\n");
                return -1.0;
            }
            //printf("loop_i %d %d\n", read, block_offset);
            block_offset += read;
        }

        // Could be a speed limitation
        generate_random(ref_buf, blocksize);

        // Verify
        if(memcmp(ref_buf, read_buf, blocksize) != 0) {
            free(ref_buf);
            free(read_buf);
            return -1.0;
        }
    }

    // Close file
    retval = fclose(fid);
    if (retval != 0) {
        printf("read file close failed%d\n", retval);
        return -1;
    }

    // Delete file
    retval = remove(fname);
    if (retval != 0) {
        printf("file deletion failed with %d\n", retval);
        return -1;
    }

    t.stop();
    free(ref_buf);
    free(read_buf);
    return t.read();
}

void report(ssize_t bytes, ssize_t blocksize, float write_duration, float read_duration) {
    char *str_bytes = format_bytes((double)bytes);
    char *str_blocksize = format_bytes((double)blocksize);
    char *str_write = format_bytes((double)bytes/write_duration);
    char *str_read = format_bytes((double)bytes/read_duration);
    printf("%10s |%10s |%10s/s |%10s/s\n", str_bytes, str_blocksize, str_write, str_read);
    free(str_bytes);
    free(str_blocksize);
    free(str_write);
    free(str_read);
}

void do_test(FileSystem *fs) {

    ssize_t tests[] = { \
        4,      8,      16,     32,     64,      128,     256, \
        512,    1024,   2048,   4096,   8192,    16384,   32768, \
        65536,  131072, 262144, 524288, 1048576, 2097152, 4194304 \
    };
    int tests_len = (int)sizeof(tests) / sizeof(ssize_t); // max 21

    // Loop through sizes
    printf("      Size | Blocksize |       Write |       Read\n");
    printf("-----------+-----------+-------------+------------\n");
    for (int i=0; i<tests_len; i++) {
        ssize_t test_size = tests[i];
        ssize_t test_blocksize = tests[i];
        ssize_t max_blocksize = 1024*16;
        if (test_blocksize > max_blocksize) {
            test_blocksize = max_blocksize;
        }

        unsigned int start_seed = 123;
        float write_duration = do_write_test(fs, start_seed, test_size, test_blocksize);
        float read_duration  = do_read_test( fs, start_seed, test_size, test_blocksize);

        // Report
        report(test_size, test_blocksize, write_duration, read_duration);
    }
    printf("-----------+-----------+-------------+------------\n");
}

int main() {
    int retval;
    BlockDevice *bd = BlockDevice::get_default_instance();
    LittleFileSystem lfs("default");
    FileSystem *fs = &lfs;
    //FileSystem *fs = FileSystem::get_default_instance();

    // https://os.mbed.com/docs/mbed-os/v5.9/reference/blockdevice.html
    retval = bd->init();
    if(retval != 0) {
        printf("init() failed with %d\n", retval);
        return -1;
    }

#define ERASE_MEMORY
#ifdef ERASE_MEMORY
    printf("Erasing memory device\n");
    retval = bd->erase(0, bd->size());
    if(retval != 0) {
        printf("erase() failed with %d\n", retval);
        return -1;
    }

    retval = fs->mount(bd);
    printf("retval=%d\n", retval);
    if (retval != 0) {
        printf("fs->mount() failed with (%d) \"%s\"\n", retval, strerror(retval));
        return -1;
    }

    retval = fs->reformat(bd);
    // https://os.mbed.com/docs/mbed-os/v5.9/reference/filesystem.html
    // https://github.com/ARMmbed/mbed-os/blob/8b6a7aacc5d2b90ba40d89c8eeb680ebee81ea18/platform/mbed_retarget.h#L132-L393
    if(retval != 0) {
        printf("fs->reformat() failed with (%d) \"%s\"\n", retval, strerror(retval));
        return -1;
    }
#endif

    printf("Initialization good,\n");
    printf("starting filesystem performance test (write/read/verify)\n");
    printf("\n");
    do_test(fs);
    printf("done\n");

    retval = fs->unmount();
    if (retval != 0) {
        printf("unmount() failed with (%d) \"%s\"\n", retval, strerror(retval));
        return -1;
    }

    retval = bd->deinit();
    if (retval != 0) {
        printf("deinit() failed with %d\n", retval);
        return -1;
    }
    while(1);
}
