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

#include <stdint.h>

#ifdef __cplusplus
extern "C"
{
#endif

/**
 * \brief IntelHex header.
 *
 */
void intelhex_header();

/**
 * \brief Write data lines to stdout in IntelHex format.
 *
 * Does not include intelhex_header() and intelhex_footer() as data is
 * usually read in small chunks because of memory limitations.
 * \param buf Pointer to the data buffer
 * \param address Value where to start IntelHex addresses
 * \param size Amount of data to be output.
 */
void intelhex_data(const uint8_t *buf, size_t address, size_t size);

/**
 * \brief IntelHex footer.
 *
 */
void intelhex_footer();

#ifdef __cplusplus
}
#endif