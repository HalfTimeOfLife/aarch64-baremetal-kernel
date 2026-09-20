# ROADMAP - AArch64 Bare-Metal Kernel

Format inspired by [Keep a Changelog](https://keepachangelog.com/).

---

## [0.3] - ARM Timer

Introduce the ARM generic timer and periodic interrupts.

### Planned
- Generic timer configuration
- Timer interrupt
- Interrupt acknowledgement
- Periodic timer tick
- Basic timekeeping

---

## [0.4] - Memory Management

Introduce physical memory management and virtual memory.

### Planned
- Physical memory layout
- Basic physical memory allocator
- Page tables
- MMU configuration
- Virtual memory mapping
- Transition from physical to virtual addressing

---

## [0.5] - Exception Levels and User Mode

Introduce multiple AArch64 exception levels and kernel/user separation.

### Planned
- EL1 and EL0
- Exception level detection
- EL0 transition
- `ERET`
- Separate kernel and user execution
- Initial user-mode program

---

## [0.6] - Multitasking

Introduce execution contexts and a basic scheduler.

### Planned
- CPU context saving and restoring
- Task structure
- Task creation
- Context switching
- Round-robin scheduler
- Multiple kernel tasks

---

## [0.7] - Drivers and Peripherals

Expand hardware support beyond the basic UART driver.

### Planned
- Improved UART driver
- GPIO support
- Storage device support
- Basic device abstraction
- Additional QEMU `virt` peripherals

---

## [1.0] - Minimal Operating System

Consolidate the previous components into a small usable operating system.

### Planned
- Clean boot process
- Exception and interrupt handling
- Timer
- Physical and virtual memory management
- Kernel and user execution
- Multitasking
- Basic drivers
- Minimal user interface
- Complete documentation

---

## Status summary

| Version | Feature | Status |
|---|---|---|
| v0.1 | Boot and UART | Shipped |
| v0.2 | Exceptions and interrupts | Shipped |
| v0.3 | ARM timer | Planned |
| v0.4 | Memory management and MMU | Planned |
| v0.5 | Exception levels and user mode | Planned |
| v0.6 | Multitasking and scheduler | Planned |
| v0.7 | Drivers and peripherals | Planned |
| v1.0 | Minimal operating system | Planned |