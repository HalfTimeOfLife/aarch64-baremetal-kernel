// ------------------------------------------------------------------
// Physical memory layout (QEMU virt)
// ------------------------------------------------------------------

// Ram base address on QEMU virt
.equ RAM_BASE,           0x40000000

// Must stay consistent with the -m option given to QEMU (128 MB)
.equ RAM_SIZE,           0x8000000

// First address outside the RAM (exclusive bound)
.equ RAM_END,            RAM_BASE + RAM_SIZE

// 4 KB pages (translation granule)
.equ PAGE_SHIFT,         12
.equ PAGE_SIZE,          1 << PAGE_SHIFT

// ------------------------------------------------------------------
// Virtual memory layout
// ------------------------------------------------------------------

// Kernel virtual address = physical address + this offset.
// Must match KERNEL_VA_OFFSET in linker.ld
.equ KERNEL_VA_OFFSET,   0xFFFF000000000000

// ------------------------------------------------------------------
// Translation table descriptors (4 KB granule)
// ------------------------------------------------------------------

// Bits [47:12]: output address (next table, or physical page).
.equ DESCR_ADDR_MASK,    0x0000FFFFFFFFF000

// Bits [1:0]. 0b11 means "table" at levels 0-2 and "page" at level 3.
.equ DESCR_VALID,        1
.equ DESCR_TYPE_TABLE,   0b11
.equ DESCR_TYPE_PAGE,    0b11

// Page attributes
.equ DESCR_AF,           (1 << 10)      // Access Flag
.equ DESCR_SH_INNER,     (0b11 << 8)    // Shareability
.equ DESCR_AP_RO,        (1 << 7)       // AP[2]: read-only
.equ DESCR_PXN,          (1 << 53)      // Privileged execute-never (EL1)
.equ DESCR_UXN,          (1 << 54)      // Unprivileged execute-never (EL0)

// Memory type, index into MAIR_EL1
.equ MT_DEVICE,          0
.equ MT_NORMAL,          1

// Indexes shifted into the AttrIndx field, bits [4:2].
.equ DESCR_MT_DEVICE,    (MT_DEVICE << 2)
.equ DESCR_MT_NORMAL,    (MT_NORMAL << 2)

// ------------------------------------------------------------------
// Page profiles
// ------------------------------------------------------------------

.equ PAGE_RAM,           (DESCR_MT_NORMAL | DESCR_AF | DESCR_SH_INNER | DESCR_UXN)
.equ PAGE_DEVICE,        (DESCR_MT_DEVICE | DESCR_AF | DESCR_PXN | DESCR_UXN)
.equ PAGE_RAM_RO,        (PAGE_RAM | DESCR_AP_RO)
.equ PAGE_RAM_NX,        (PAGE_RAM | DESCR_PXN)


// ------------------------------------------------------------------
// MAIR_EL1 configuration
// See : https://dannasman.github.io/aarch64-mmu.html
// ------------------------------------------------------------------

// MAIR_EL1: one 8-bit attribute per index, the index being the AttrIndx
.equ MAIR_ATTR_DEVICE,  0x00    // Device-nGnRnE: no caching, no reordering
.equ MAIR_ATTR_NORMAL,  0xFF    // Normal, inner and outer write-back, read/write-allocate
.equ MAIR_VALUE,        ((MAIR_ATTR_DEVICE << (MT_DEVICE * 8)) | (MAIR_ATTR_NORMAL << (MT_NORMAL * 8)))

// ------------------------------------------------------------------
// TCR_EL1 configuration
// See : https://dannasman.github.io/aarch64-mmu.html
// ------------------------------------------------------------------

.equ TCR_T0SZ,      (16 << 0)       // 64 - 16 = 48-bit virtual addresses
.equ TCR_IRGN0,     (1 << 8)        // table walks: inner write-back, allocate
.equ TCR_ORGN0,     (1 << 10)       // table walks: outer write-back, allocate
.equ TCR_SH0,       (3 << 12)       // table walks: inner shareable
.equ TCR_TG0,       (0 << 14)       // 4 KB granule
.equ TCR_T1SZ,      (16 << 16)
.equ TCR_IRGN1,     (1 << 24)
.equ TCR_ORGN1,     (1 << 26)
.equ TCR_SH1,       (3 << 28)
.equ TCR_TG1,       (2 << 30)       // 4 KB granule (encoding differs from TG0)

.equ TCR_VALUE,     (TCR_T0SZ | TCR_IRGN0 | TCR_ORGN0 | TCR_SH0 | TCR_TG0 | TCR_T1SZ | TCR_IRGN1 | TCR_ORGN1 | TCR_SH1 | TCR_TG1)

// ------------------------------------------------------------------
// SCTLR_EL1 configuration
// ------------------------------------------------------------------

.equ SCTLR_M,   (1 << 0)      // MMU enable
.equ SCTLR_C,   (1 << 2)      // data cache enable
.equ SCTLR_I,   (1 << 12)     // instruction cache enable

