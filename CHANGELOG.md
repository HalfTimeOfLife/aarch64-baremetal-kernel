# CHANGELOG - AArch64 Bare-Metal Kernel

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [0.4] - Memory Management

Introduces physical memory management, 4-level page tables, the MMU with a higher-half kernel, and a test suite.

### Added
- `src/mm/pmm.s`: physical page allocator (`page_alloc`/`page_free`/`pmm_init`), free list over `[_heap_start, RAM_END[`
- `src/mm/pgtable.s`: `map_page`, `map_range`, `translate` (4-level, 4 KB granule translation tables)
- `src/mm/mmu.s`: `mmu_config` (MAIR_EL1/TCR_EL1), `mmu_map_identity`, `mmu_map_high`, `mmu_enable`, `mmu_enable_caches`
- `src/exceptions/handlers.s`: `el_synchronous` now dispatches by EC (skips data aborts after counting them, halts on anything else)
- `linker.ld`: kernel linked at high virtual addresses (`TTBR1_EL1`, `0xFFFF000040000000`), loaded at its physical address; `_heap_start` kept absolute
- `src/tests/tests.s`: 25 checks (registers, allocator, hardware translation via `AT`/`PAR_EL1`, kernel location, aliasing, permissions)
- `scripts/test.sh`, `make test`: runs the kernel under QEMU and validates the test output
- `.github/workflows/ci.yml`: CI build and test on every push

### Notes
- Validated under QEMU: identity-mapped RAM/GIC/UART, a direct high-half mapping of the RAM, read-only and non-executable page permissions, and a kernel running entirely from the high half
- Full details in [notes/v04.md](notes/v04.md)

---

## [0.3] - ARM Timer

Introduces the ARM generic timer, running as a periodic PPI through the GICv2 configured in v0.2.

### Added
- `src/timer/timer.s`: `timer_init`/`timer_set_interval`, configures `CNTP_TVAL_EL0`/`CNTP_CTL_EL0` for a ~100 Hz tick (non-secure EL1 physical timer, GIC PPI ID 30)
- `src/gic/gic.s`: `gic_init` extended to enable PPI 30 alongside SGI 0
- `src/exceptions/handlers.s`: `el_irq` now dispatches by interrupt ID; `timer_irq` re-arms the timer, increments `tick_count`, and prints it every 512 ticks
- `bl timer_init` added to `_start`, after `gic_init` and before IRQ unmask

### Notes
- Validated on QEMU: tick count increases by exactly 512 between each print, confirming periodic firing and correct re-arming
- Full details and register reference in [notes/v03.md](notes/v03.md)

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
