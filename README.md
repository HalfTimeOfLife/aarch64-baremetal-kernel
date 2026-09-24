# AArch64 Bare-Metal Kernel

A small bare-metal kernel for AArch64 (ARMv8-A), built from scratch and executed on QEMU's `virt` machine.

---

## Target platform

- Execution environment: QEMU
- Machine: QEMU `virt`
- Architecture: AArch64 (ARMv8-A)
- CPU: `cortex-a57`
- Language: AArch64 assembly

---

## Project structure

```text
aarch64-baremetal-kernel/
├── notes
│   ├── v01.md
│   ├── v02.md
│   └── v03.md
├── scripts
│   └── check_setup.sh
├── src
│   ├── boot
│   │   └── boot.s
│   ├── exceptions
│   │   ├── handlers.s
│   │   └── vectors.s
│   ├── gic
│   │   ├── gic.inc
│   │   └── gic.s
│   ├── timer
│   │   └── timer.s
│   └── uart
│       └── uart.s
├── .gitignore
├── CHANGELOG.md
├── LICENSE
├── Makefile
├── README.md
├── ROADMAP.md
└── linker.ld
```

---

## Project roadmap

The project is developed incrementally through four releases:

| Version | Feature                                           |
| ------- | ------------------------------------------------- |
| v0.1    | Boot and UART                                     |
| v0.2    | Exceptions, interrupts and exception vector table |
| v0.3    | ARM timer and periodic interrupts                 |
| v0.4    | Physical memory management and MMU                |
| v0.5    | Exception levels and kernel/user separation       |
| v0.6    | Multitasking and scheduler                        |
| v0.7    | Drivers and peripherals                           |
| v1.0    | Minimal usable operating system                   |


See [ROADMAP.md](ROADMAP.md) for the complete development and study roadmap.

---

## Requirements

A Linux environment with the following tools installed:

- `aarch64-none-elf-gcc`
- `aarch64-none-elf-binutils`
- `make`
- `qemu-system-aarch64`
- `gdb-multiarch`

The [scripts/check_setup.sh](scripts/check_setup.sh) script can be used to verify that all required tools are installed and available in the environment.



---

## Development environment

Development may be performed using WSL2 with Ubuntu.

For example:

```
sudo apt update
sudo apt install -y build-essential qemu-system-arm gdb-multiarch
```

The `aarch64-none-elf` cross compiler should then be installed separately according to the host distribution or toolchain being used.

The repository should preferably be kept inside the WSL filesystem rather than under `/mnt/c/` for better filesystem performance.

---

## Run

Build the kernel with:

```bash
make
```

Then run it with QEMU:

```bash
qemu-system-aarch64 \
    -M virt \
    -cpu cortex-a57 \
    -nographic \
    -kernel build/kernel.elf
```

Expected output depends on the current version. 

> See [notes/](notes/) for the detailed walkthrough of each release.

The kernel then enters an infinite loop.

---

## Resources

### Primary study resource

[CheesecakeOS](https://github.com/jmielkeway/ccos4rbpi_volume0)

CheesecakeOS is used as the primary learning resource for the project.

### ARM documentation

[Arm Architecture Reference Manual for A-profile architecture (DDI 0487)](https://developer.arm.com/documentation/ddi0487/latest)

[Arm Cortex-A Series Programmer's Guide for Armv8-A (DEN0024)](https://developer.arm.com/documentation/den0024/latest)

[Arm Generic Interrupt Controller Architecture Specification (GICv2)](https://developer.arm.com/documentation/ihi0048/latest/)

### QEMU

[QEMU `virt` machine documentation](https://www.qemu.org/docs/master/system/arm/virt.html)

### Additional reference

[OSDev Wiki](https://wiki.osdev.org/)

--- 

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
