/* mbed Microcontroller Library
 * Copyright (c) 2018 ARM Limited
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
 */
#include "mbed.h"
#include <stdio.h>
#include <algorithm>
#include "mbed-trace/mbed_trace.h"
#define TRACE_GROUP "APP"

//NOTICE: DEFAULT IS FOR SPI FLASH
#define TARGET_STORAGE_SIZE (4*1024*1024)

#define COMPARE_ONLY  //don't use this for the first time.

// Block devices
#if COMPONENT_QSPIF
#include "QSPIFBlockDevice.h"
#endif

#if COMPONENT_SPIF
#include "SPIFBlockDevice.h"
#endif

#if COMPONENT_DATAFLASH
#include "DataFlashBlockDevice.h"
#endif 

#if COMPONENT_SD
#include "SDBlockDevice.h"
#endif 

#include "HeapBlockDevice.h"

// Physical block device, can be any device that supports the BlockDevice API
/*
SDBlockDevice bd(
        MBED_CONF_SD_SPI_MOSI,
        MBED_CONF_SD_SPI_MISO,
        MBED_CONF_SD_SPI_CLK,
        MBED_CONF_SD_SPI_CS);
*/
SPIFBlockDevice bd(
        MBED_CONF_SPIF_DRIVER_SPI_MOSI,
        MBED_CONF_SPIF_DRIVER_SPI_MISO,
        MBED_CONF_SPIF_DRIVER_SPI_CLK,
        MBED_CONF_SPIF_DRIVER_SPI_CS);

// Entry point for the example
int main() {
    int diff_count = 0;

#ifdef MBED_CONF_MBED_TRACE_ENABLE
    mbed_trace_init();
#endif

    printf("--- Mbed OS block device example ---\n");

    // Initialize the block device
    tr_debug("bd.init()\n");
    int err = bd.init();
    tr_debug("bd.init -> %d\n", err);
    if(err)
    {
        printf("BlockDevice.Init() failed, error: %d\n", err);
    }

    // Get device geometry
    bd_size_t read_size    = bd.get_read_size();
    bd_size_t program_size = bd.get_program_size();
    bd_size_t erase_size   = bd.get_erase_size();
    bd_size_t size         = bd.size();

    printf("--- Block device geometry ---\n");
    printf("read_size:    %lld B\n", read_size);
    printf("program_size: %lld B\n", program_size);
    printf("erase_size:   %lld B\n", erase_size);
    printf("size:         %lld B\n", size);
    printf("---\n");

    // Allocate a block with enough space for our data, aligned to the
    // nearest program_size. This is the minimum size necessary to write
    // data to a block.
    //size_t buffer_size = sizeof("Hello Storage!") + program_size-1;
    //buffer_size = buffer_size - (buffer_size % program_size);
    //char *buffer = new char[buffer_size];

    char str[] = "Hello Storage!";
    size_t str_size = sizeof(str);
    size_t buffer_size = 16384;
    char *buffer = new char[buffer_size];
    char *readbuf = new char[buffer_size];

    // Update buffer with our string we want to store
    //strncpy(buffer, "Hello Storage!", buffer_size);
    for(size_t i = 0; i < buffer_size; i++)
    {
        buffer[i] = str[i % str_size];
    }

    for(size_t idx = 0; idx < TARGET_STORAGE_SIZE/buffer_size; idx++)
    {
            int result = 0;

#if !defined(COMPARE_ONLY)
            if(erase_size < buffer_size)
            {
                for(size_t t_e = 0; t_e < buffer_size/erase_size; t_e++)
                {
		    tr_debug("bd.erase(%d, %lld)\n", idx*buffer_size + t_e*erase_size , erase_size);
		    err = bd.erase(idx*buffer_size + t_e*erase_size, erase_size);
		    tr_debug("bd.erase -> %d\n", err);
		    if(err)
		    {
			printf("BlockDevice.erase() failed, error: %d\n", err);
		    }
                }
            }
            else
            {
		tr_debug("bd.erase(%d, %lld)\n", idx*buffer_size, erase_size);
		err = bd.erase(0, erase_size);
		tr_debug("bd.erase -> %d\n", err);
		if(err)
		{
		    printf("BlockDevice.erase() failed, error: %d\n", err);
		}
            }

	    tr_debug("bd.program(%p, %d, %d)\n", buffer, idx*buffer_size, buffer_size);
	    err = bd.program(buffer, idx*buffer_size, buffer_size);
	    tr_debug("bd.program -> %d\n", err);
	    if(err)
            {
	        printf("BlockDevice.program() failed, error: %d\n", err);
            }

#endif
	    // Read the data from the first block, note that the program_size must be
	    // a multiple of the read_size, so we don't have to check for alignment
	    tr_debug("bd.read(%p, %d, %d)\n", readbuf, idx*buffer_size, buffer_size);
	    err = bd.read(readbuf, idx*buffer_size, buffer_size);
	    tr_debug("bd.read -> %d\n", err);
	    if(err)
            {
	        printf("BlockDevice.read() failed, error: %d\n", err);
            }

            result = memcmp(buffer, readbuf, buffer_size);

            tr_debug("[BUFFER BLOCK %d COMPARE]: %d\n", idx, result);

            if(result != 0)
            {
                printf("[0x%x - 0x%x] content mismatch\n", idx*buffer_size, idx*buffer_size + buffer_size-1);
                diff_count++;
            }
	    // Clobber the buffer so we don't get old data
	    memset(readbuf, 0xcc, buffer_size);


    }

    if(diff_count == 0)
    {
        printf("RESULT: all content identical.\n");
    }
    else
    {
        printf("RESULT: %d blocks of content mismatch\n", diff_count);
    }

    diff_count = 0;

    // Deinitialize the block device
    tr_debug("bd.deinit()\n");
    err = bd.deinit();
    tr_debug("bd.deinit -> %d\n", err);
    if(err)
    {
        printf("BlockDevice.deinit() failed, error: %d\n", err);
    }

    printf("--- done! ---\n");
}

