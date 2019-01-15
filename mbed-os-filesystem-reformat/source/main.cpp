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
#include <stdint.h>
#include <inttypes.h>
#include "BlockDevice.h"
#include "FileSystem.h"

int main() {
    int retval;
    BlockDevice *bd = BlockDevice::get_default_instance();
    FileSystem *fs = FileSystem::get_default_instance();

    retval = bd->init();
    printf("init() = %d\n", retval);
    printf("size() = %" PRIu64 "\n", (uint64_t)bd->size());

    retval = bd->erase(0, bd->size());
    printf("erase() = %d\n", retval);

    retval = fs->reformat(bd);
    printf("reformat() = %d\n", retval);

    retval = bd->sync();
    printf("sync() = %d\n", retval);

    retval = bd->deinit();
    printf("deinit() = %d\n", retval);
    while(1);
}
