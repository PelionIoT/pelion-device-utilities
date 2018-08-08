#!/bin/sh
# Copyright 2018 ARM Ltd.

REPORT_FILE="./sysinfo.txt"
{
	divider()
	{
		set +x
		echo "---------------\n"
		set -x
	}

	# Stop on error
	set -e

	# Print all commands
	set -x

	# ==================
	# User & permissions
	# ==================
	# User ID
    id -u
    divider

    # Username
    who
    divider

    # Folder permissions
    ls -ld .
    divider

	# =======================
	# CPU & Architecture info
	# =======================
	# There is duplication below because, not all of these are available in every platform
	if [ -e /proc/cpuinfo ]; then
		cat /proc/cpuinfo
		divider
	fi

	if [  `command -v arch` ]; then
		# achine architecture
		arch
		divider
	fi

	if [ `command -v uname` ]; then
		# kernel name, version, release
		uname -a
		divider
	fi

	if [ -e /etc/lsb-release ] || [ -e /etc/os-release ]; then
		# distro detection
		cat /etc/*release
		divider
	fi

	echo "OSTYPE="$OSTYPE
	divider

	# ============
	# Flash layout
	# ============
	if [ `command -v lsblk` ]; then
		lsblk
		divider
	fi

	if [ -e /proc/mtd ]; then
		cat /proc/mtd
		divider
	fi

	# =============
	# Default shell
	# =============
	echo "$SHELL"
	divider

	if [ "$SHELL" = "/bin/sh" ] || [ "$SHELL" = "/bin/bash" ]; then
		"$SHELL" --version
		divider
	fi

	# ===============
	# Busybox version
	# ===============
	if [ `command -v busybox` ]; then
		busybox --help
		divider
	fi

	# ===========
	# System time
	# ===========
	if [ `command -v date` ]; then
		date
		divider
	fi

	# ===========
	# Compilation
	# ===========
	if [ `command -v gcc` ]; then
		gcc --version
		divider
	fi

	if [ `command -v iccarm` ]; then
		iccarm --version
		divider
	fi

	if [ `command -v armcc` ]; then
		armcc
		divider
	fi

	if [ `command -v cmake` ]; then
		cmake --version
		divider
	fi
} > "$REPORT_FILE" 2>&1

cat "$REPORT_FILE"
