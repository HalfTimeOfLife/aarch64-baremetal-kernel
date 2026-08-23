#!/usr/bin/env bash

echo "Checking AArch64 bare-metal kernel setup..."
echo

missing=0

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        version=$("$1" --version | head -n 1)
        echo "[OK] $version"
    else
        echo "[MISSING] $1"
        missing=1
    fi
}

check_command aarch64-none-elf-gcc
check_command aarch64-none-elf-ld
check_command aarch64-none-elf-objdump
check_command aarch64-none-elf-nm
check_command make
check_command qemu-system-aarch64
check_command gdb-multiarch

if [ "$missing" -eq 0 ]; then
    echo
    echo "Setup OK."
else
    echo
    echo "Setup check failed."
    exit 1
fi