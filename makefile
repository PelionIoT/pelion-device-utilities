# Copyright 2018 ARM Ltd.
PACKAGE_FILES := $(wildcard *.sh)
PACKAGE_FILES += $(wildcard *.pem)
PACKAGE_FILES += $(wildcard *.md5)
PACKAGE_FILES += $(wildcard *.sha256)
PACKAGE_FILES += README.md
PACKAGE_FILES += $(wildcard certificates/*.pem)

# Compressed tar archive of the important files
.PHONY: tar
tar: preflight.tar.gz

# Uncompressed package incase gzip is not available on target device
.PHONY: tar_uncompressed
tar_uncompressed: preflight.tar

# base64 encoded package to be transfered over serial port
.PHONY: base64
base64: preflight.tar.gz
	base64 $^

.PHONY: base64_uncompressed
base64_uncompressed: preflight.tar
	base64 $^

# Recipes
preflight.tar.gz: ${PACKAGE_FILES}
	tar -czvf $@ ${PACKAGE_FILES}

preflight.tar: ${PACKAGE_FILES}
	tar -cvf $@ ${PACKAGE_FILES}

