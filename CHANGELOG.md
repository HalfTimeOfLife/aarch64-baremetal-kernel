# CHANGELOG - AArch64 Bare-Metal Kernel

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [0.2] - Exceptions and Interrupts

Introduces the AArch64 exception mechanism, a full exception vector table, and the GIC (interrupt controller), running on QEMU `virt`'s GICv2.

### Added
- `src/exceptions/vectors.s`: AArch64 exception vector table, 16 entries, 2 KB aligned, 14 unused stubs + synchronous and IRQ handler entries (VBAR_EL1 + 0x200 / + 0x280)
- `src/exceptions/handlers.s`: synchronous handler (dumps `ELR_EL1`/`SPSR_EL1`/`ESR_EL1`), IRQ handler (dumps `GICC_IAR`), both returning via `eret`
- `src/gic/gic.s`, `src/gic/gic.inc`: GICv2 driver (`gic_init`), Distributor + CPU interface setup
- `src/uart/uart.s`: `uart_put_hex`, prints a 64-bit register value in hexadecimal
- `VBAR_EL1` configured and GIC initialized in `_start`, before any code that could trigger an exception

### Notes
- Validated with a deliberate `svc #0` (EC=0x15 in `ESR_EL1`) and a self-targeted SGI 0 via `GICD_SGIR`, both correctly routed, handled, and returned from
- Full details in [notes/v02.md](notes/v02.md)

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
- Full details in [notes/v01.md](notes/v01.md)
