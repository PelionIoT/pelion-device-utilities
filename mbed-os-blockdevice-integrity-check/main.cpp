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
#include "BlockDevice.h"
#define TRACE_GROUP "APP"

#define TARGET_STORAGE_SIZE_IN_TEST (0)

//#define COMPARE_ONLY  //don't use this for the first time.

// Entry point for the example
int main() {
    int diff_count = 0;
    BlockDevice *bd = BlockDevice::get_default_instance();

#ifdef MBED_CONF_MBED_TRACE_ENABLE
    mbed_trace_init();
#endif

    printf("--- Mbed OS block device integrity check ---\n");

    // Initialize the block device
    tr_debug("bd->init()\n");
    int err = bd->init();
    tr_debug("bd->init -> %d\n", err);
    if(err)
    {
        printf("BlockDevice initialization failed, error: %d\n", err);
    }

    // Get device geometry
    bd_size_t read_size    = bd->get_read_size();
    bd_size_t program_size = bd->get_program_size();
    bd_size_t erase_size   = bd->get_erase_size();
    bd_size_t size         = bd->size();

    printf("--- Block device geometry ---\n");
    printf("read_size:    %lld B\n", read_size);
    printf("program_size: %lld B\n", program_size);
    printf("erase_size:   %lld B\n", erase_size);
    printf("size:         %lld B\n", size);
    printf("---\n");

    char str[] = "Hello Storage!";
    size_t str_size = sizeof(str);
    size_t buffer_size = 16384;
    size_t chunk_count = (int32_t)(bd->size()/buffer_size);
    char *buffer = new char[buffer_size];
    char *readbuf = new char[buffer_size];
    size_t idx = 0;

#ifdef TARGET_STORAGE_SIZE_IN_TEST
    if(TARGET_STORAGE_SIZE_IN_TEST > bd->size())
    {
        printf("Invalid target test storage size specified. Test stopped.\n");
        return -1;
    }
    else if(TARGET_STORAGE_SIZE_IN_TEST > 0)
    {
        printf("Performing partial storage test.\n");
        chunk_count = TARGET_STORAGE_SIZE_IN_TEST / buffer_size;
    }
    else
    {
        printf("Performing full storage test.\n");
    }
#endif

    printf("\nProgressing..............");

    // Update buffer with our string we want to store
    //strncpy(buffer, "Hello Storage!", buffer_size);
    for(size_t i = 0; i < buffer_size; i++)
    {
        buffer[i] = str[i % str_size];
    }

    for(idx = 0; idx < chunk_count; idx++)
    {
            int result = 0;

            switch(idx % 4)
            {
                case 0:
                    printf("\b\b\b\b\b\b\b\b\b\b\b%7.3f%%  /", ((float)idx/(float)chunk_count)*100);
                    break;
                case 1:
                    printf("\b\b\b\b\b\b\b\b\b\b\b%7.3f%%  -", ((float)idx/(float)chunk_count)*100);
                    break;
                case 2:
                    printf("\b\b\b\b\b\b\b\b\b\b\b%7.3f%%  \\", ((float)idx/(float)chunk_count)*100);
                    break;
                case 3:
                default:
                    printf("\b\b\b\b\b\b\b\b\b\b\b%7.3f%%  |", ((float)idx/(float)chunk_count)*100);
                    break;
            }

            fflush(stdout);

#if !defined(COMPARE_ONLY)
            if(erase_size < buffer_size)
            {
                for(size_t t_e = 0; t_e < buffer_size/erase_size; t_e++)
                {
		    tr_debug("bd->erase(%d, %lld)\n", idx*buffer_size + t_e*erase_size , erase_size);
		    err = bd->erase(idx*buffer_size + t_e*erase_size, erase_size);
		    tr_debug("bd->erase -> %d\n", err);
		    if(err)
		    {
			printf("BlockDevice.erase() failed, error: %d\n", err);
		    }
                }
            }
            else
            {
		tr_debug("bd->erase(%d, %lld)\n", idx*buffer_size, erase_size);
		err = bd->erase(0, erase_size);
		tr_debug("bd->erase -> %d\n", err);
		if(err)
		{
		    printf("BlockDevice.erase() failed, error: %d\n", err);
		}
            }

	    tr_debug("bd->program(%p, %d, %d)\n", buffer, idx*buffer_size, buffer_size);
	    err = bd->program(buffer, idx*buffer_size, buffer_size);
	    tr_debug("bd->program -> %d\n", err);
	    if(err)
            {
	        printf("BlockDevice.program() failed, error: %d\n", err);
            }

#endif
	    // Read the data from the first block, note that the program_size must be
	    // a multiple of the read_size, so we don't have to check for alignment
	    tr_debug("bd->read(%p, %d, %d)\n", readbuf, idx*buffer_size, buffer_size);
	    err = bd->read(readbuf, idx*buffer_size, buffer_size);
	    tr_debug("bd->read -> %d\n", err);
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
    
    printf("\b\b\b\b\b\b\b\b\b\b\b%7.3f%%  |", ((float)idx/(float)chunk_count)*100);
    printf("\n\n");

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
    tr_debug("bd->deinit()\n");
    err = bd->deinit();
    tr_debug("bd->deinit -> %d\n", err);
    if(err)
    {
        printf("BlockDevice.deinit() failed, error: %d\n", err);
    }

    printf("--- done! ---\n");
}

