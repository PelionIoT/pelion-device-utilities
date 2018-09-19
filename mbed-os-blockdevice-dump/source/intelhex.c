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

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "intelhex.h"

/**
 * \brief Print extended address entry.
 *
 * \param address The two high bytes of a full 32bit address.
 */
void intelhex_extended_address(uint16_t address);

void intelhex_header()
{
}

void intelhex_line(const uint8_t *buf, size_t address, size_t size)
{
    /* At every start of every 65536 block, write extended address */
    if (address % 0x10000 == 0) {
        intelhex_extended_address((uint16_t)(address >> 16)); /* throw away low bytes*/
    }

    uint8_t checksum = 0;

    /* Start */
    printf(":");
    /* Byte count*/
    printf("%02X", (unsigned int)size);
    checksum += size;
    /* Address */
    printf("%04X", (uint16_t)address); /* throw away high bytes */
    checksum += address >> 8;
    checksum += address;
    /* Record type */
    printf("%02X", 0x00);
    checksum += 0x00;
    /* Data */
    for (size_t i = 0; i < size; i++)
    {
        printf("%02X", buf[i]);
        checksum += buf[i];
    }
    checksum = ~checksum + 1; /* two's complement */
    printf("%02X\n", checksum);
}

void intelhex_data(const uint8_t *buf, size_t address, size_t size)
{
    const size_t bytes_per_line = 16;
    for (size_t local_offset = 0; local_offset < size;)
    {
        size_t bytes_available = size - local_offset;
        size_t line_bytes = bytes_available;
        if (line_bytes > bytes_per_line)
        {
            line_bytes = bytes_per_line;
        }
        intelhex_line(buf + local_offset, address + local_offset, line_bytes);
        local_offset += line_bytes;
    }
}

void intelhex_extended_address(uint16_t address)
{
    uint8_t checksum = 0;
    checksum += 0x02 + 0x00 + 0x00 + 0x04;
    checksum += address >> 8;
    checksum += address;
    checksum = ~checksum + 1;
    printf(":02000004%04X%02X\n", address, checksum);
}

void intelhex_footer()
{
    /* End-of-file record */
    printf(":00000001FF\n");
}
