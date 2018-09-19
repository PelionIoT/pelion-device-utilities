#!/bin/sh
# Copyright 2018 ARM Ltd.

# Load common variables and functions
. ./common.sh

# ==================
# User & permissions
# ==================
# User ID
echo "id -u"
id -u
divider

# Username
if [ `command -v who` ]; then
	echo "who"
	who
	divider
fi

# Folder permissions
echo "ls -ld ."
ls -ld .
divider

# =======================
# CPU & Architecture info
# =======================
# There is duplication below because, not all of these are available in every platform
if [ -e /proc/cpuinfo ]; then
	echo "cat /proc/cpuinfo"
	cat /proc/cpuinfo
	divider
fi

if [  `command -v arch` ]; then
	echo "arch"
	arch
	divider
fi

if [ `command -v uname` ]; then
	echo "uname -a"
	# kernel name, version, release
	uname -a
	divider
fi

if [ -e /etc/lsb-release ] || [ -e /etc/os-release ]; then
	echo "cat /etc/*release"
	# distribution info
	cat /etc/*release
	divider
fi

echo "OSTYPE=$OSTYPE"
divider

# ============
# Flash layout
# ============
if [ `command -v lsblk` ]; then
	echo "lsblk"
	lsblk
	divider
fi

if [ -e /proc/mtd ]; then
	echo "cat /proc/mtd"
	cat /proc/mtd
	divider
fi

# ===========
# System time
# ===========
if [ `command -v date` ]; then
	echo "date"
	date
	divider
fi

# if root, check Real-Time-Clock (RTC) with hwclock
if [ `command -v hwclock` ] && [ "`id -u`" = "0" ]; then
	echo "A Real-Time-Clock (RTC) is available on the system."
	echo "hwclock -r"
	hwclock -r || :
	divider
fi

# =============
# Tool versions
# =============
echo "SHELL=$SHELL"
divider

if [ "$SHELL" = "/bin/sh" ] || [ "$SHELL" = "/bin/bash" ]; then
	echo "\$SHELL --version"
	"$SHELL" --version
	divider
fi

if [ `command -v busybox` ]; then
	echo "busybox --help"
	busybox --help
	divider
fi

if [ `command -v gcc` ]; then
	echo "gcc --version"
	gcc --version
	divider
fi

if [ `command -v iccarm` ]; then
	echo "iccarm --version"
	iccarm --version || :
	divider
fi

if [ `command -v armcc` ]; then
	echo "armcc"
	armcc
	divider
fi

if [ `command -v cmake` ]; then
	echo "cmake --version"
	cmake --version
	divider
fi

if [ `command -v dd` ]; then
	echo "dd --version"
	# busybox dd --version returns non-zero value -> "|| :"
	dd --version || :
fi

if [ `command -v openssl` ]; then
	echo "openssl version"
	openssl version
fi
