# AArch64 Bare-Metal Kernel

A minimal bare-metal kernel for AArch64 (ARMv8-A), built from scratch on QEMU's `virt` machine. The goal is to learn the ARM64 architecture and kernel fundamentals.

## Target platform

- Architecture: AArch64 (ARMv8-A)
- Machine: QEMU

## Setup (WSL) (FOR THE DEV WILL BE REMOVED)

Development happens inside WSL2 (Ubuntu).

1. Install WSL with Ubuntu (from an elevated PowerShell):
   ```powershell
   wsl --install -d Ubuntu
   ```
   Restart if prompted, then finish the Ubuntu first-run setup (username/password).

2. Inside the Ubuntu/WSL shell, update packages and install the build tools:
   ```bash
   sudo apt update
   sudo apt install -y build-essential gdb-multiarch qemu-system-arm gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu
   ```

3. Verify the toolchain and emulator:
   ```bash
   aarch64-linux-gnu-gcc --version
   qemu-system-aarch64 --version
   ```

4. Clone the project and build from inside WSL (not from the Windows filesystem, i.e. keep the repo under `~/`, not `/mnt/c/...`, for faster I/O):
   ```bash
   cd ~
   git clone <repo-url>
   cd <repo-name>
   make
   make qemu
   ```

## Resources

- [Bare-metal C programming on ARM](https://github.com/umanovskis/baremetal-arm)
- [ARM Architecture Reference Manual for A-profile architecture (DDI 0487)](https://developer.arm.com/documentation/ddi0487/latest)
- [ARM Cortex-A Series Programmer's Guide for ARMv8-A (DEN0024)](https://developer.arm.com/documentation/den0024/latest)
- [QEMU `virt` machine documentation](https://www.qemu.org/docs/master/system/arm/virt.html)
- [OSDev wiki, Raspberry Pi Bare Bones](https://wiki.osdev.org/Raspberry_Pi_Bare_Bones)
- [s-matyukevich/raspberry-pi-os](https://github.com/s-matyukevich/raspberry-pi-os)