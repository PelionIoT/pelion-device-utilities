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
#include "inttypes.h"
#include "BlockDevice.h"

#if (MBED_VERSION < MBED_ENCODE_VERSION(5,10,0))
    #error "BlockDevice::get_default_instance() was first introduced in Mbed OS 5.10"
#endif

int main() {
    int retval;

    BlockDevice *bd = BlockDevice::get_default_instance();
    retval = bd->init();
    printf("init() = %d\n", retval);

    if (retval == 0) {
        printf("size() = %" PRIu64 "\n", (uint64_t)bd->size());
        printf("get_read_size() = %" PRIu64 "\n", (uint64_t)bd->get_read_size());
        printf("get_program_size() = %" PRIu64 "\n", (uint64_t)bd->get_program_size());
        printf("get_erase_size() = %" PRIu64 "\n", (uint64_t)bd->get_erase_size());
        int erase_value = bd->get_erase_value();
        if (erase_value > 0) {
            printf("get_erase_value() = 0x%02x\n", erase_value);
        } else {
            printf("get_erase_value() = random\n");
        }
    }

    retval = bd->deinit();
    printf("deinit() = %d\n", retval);
    while(1);
}
