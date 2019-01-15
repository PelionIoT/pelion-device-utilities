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
#include "BlockDevice.h"
#include "intelhex.h"

int block_dump(BlockDevice &bd, size_t early_stop)
{
    uint8_t buf[1024]; /* 65536 needs to be dividable by this number */
    size_t bd_size = bd.size();
    intelhex_header();
    for (size_t offset = 0; offset < bd_size;) {
        size_t read_size = bd_size - offset;
        if (read_size > sizeof(buf)) {
            read_size = sizeof(buf);
        }

        int retval = bd.read(buf, offset, sizeof(buf));
        if (retval != 0) {
            return retval;
        }

        intelhex_data(buf, offset, read_size);
        offset += read_size;

        if (early_stop) {
            if (offset > early_stop) {
                printf("early stop\n");
                break;
            }
        }
    }
    intelhex_footer();
    return 0;
}

int main() {
    int retval;
    BlockDevice *bd = BlockDevice::get_default_instance();
    printf("Dump start\n");

    retval = bd->init();
    printf("init() = %d\n", retval);

    retval = block_dump(*bd, 0);
    printf("block_dump() = %d\n", retval);

    retval = bd->deinit();
    printf("deinit() = %d\n", retval);

    printf("Dump done\n");
    while(1);
}

