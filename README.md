# AArch64 Bare-Metal Kernel

A small bare-metal kernel for AArch64 (ARMv8-A), built from scratch and executed on QEMU's `virt` machine.

---

## Target platform

- Execution environment: QEMU
- Machine: QEMU `virt`
- Architecture: AArch64 (ARMv8-A)
- CPU: `cortex-a53`
- Language: C and AArch64 assembly

---

## Project roadmap

The project is developed incrementally through four releases:

| Version | Feature                                     |
| ------- | ------------------------------------------- |
| v0.1    | Minimal boot and UART output                |
| v0.2    | Exception levels and exception vector table |
| v0.3    | Timer interrupts and round-robin scheduler  |
| v0.4    | IRQ-driven UART driver                      |

Each version is documented in a dedicated article explaining the concepts introduced and the implementation choices made.

See [ROADMAP.md](ROADMAP.md) for the complete development and study roadmap.

---

## Requirements

A Linux environment with the following tools installed:

- `aarch64-none-elf-gcc`
- `aarch64-none-elf-binutils`
- `make`
- `qemu-system-aarch64`
- `gdb-multiarch`

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

## Resources

### Primary study resource

[CheesecakeOS](https://github.com/jmielkeway/ccos4rbpi_volume0)

CheesecakeOS is used as the primary learning resource for the project.

### ARM documentation

[Arm Architecture Reference Manual for A-profile architecture (DDI 0487)](https://developer.arm.com/documentation/ddi0487/latest)

[Arm Cortex-A Series Programmer's Guide for Armv8-A (DEN0024)](https://developer.arm.com/documentation/den0024/latest)

### QEMU

[QEMU `virt` machine documentation](https://www.qemu.org/docs/master/system/arm/virt.html)

### Additional reference

[OSDev Wiki](https://wiki.osdev.org/)

--- 

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
