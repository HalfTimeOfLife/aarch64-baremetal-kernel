# CHANGELOG - AArch64 Bare-Metal Kernel

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [0.1] - 2026-08-23

Initial bare-metal AArch64 kernel running on QEMU's `virt` machine.

### Added

- `linker.ld`: custom linker script, kernel linked at `0x40000000`, stack layout with `_stack_bottom` and `_stack_top`
- `src/boot/boot.s`: AArch64 bare-metal boot code, stack initialization and kernel halt loop
- `src/uart/uart.s`: UART MMIO driver for QEMU `virt`, `uart_putc` and `uart_puts`, null-terminated string output, UART transmit FIFO polling through `UART_FR`, character output through `UART_DR`
- `Makefile`: assembly and linking of the kernel, automatic generation of the `build/` directory and object files
- `scripts/check_setup.sh`: development environment verification
- `build/`: generated object files and kernel ELF
- AArch64 assembly-only implementation with no C runtime or standard library

### Notes
- Tested on QEMU `virt` with the `cortex-a57` CPU model
- Kernel successfully prints `Hello, AArch64!`
