CROSS = aarch64-none-elf

AS = $(CROSS)-gcc
LD = $(CROSS)-ld

ASFLAGS = -Isrc

LD_CUSTOM = linker.ld

SRC := $(wildcard src/*/*.s)

OUTPUT_DIR := build

OBJ := $(patsubst src/%.s,$(OUTPUT_DIR)/%.o,$(SRC))

OUTPUT := $(OUTPUT_DIR)/kernel.elf

all: $(OUTPUT)

$(OUTPUT): $(OBJ) $(LD_CUSTOM)
	mkdir -p $(@D)
	$(LD) -T $(LD_CUSTOM) -o $@ $(OBJ)

$(OUTPUT_DIR)/%.o: src/%.s
	mkdir -p $(@D)
	$(AS) $(ASFLAGS) -c $< -o $@

help:
	@echo "Targets:"
	@echo "  make release   Build kernel"
	@echo "  make clean     Remove build files"

clean:
	rm -rf $(OUTPUT_DIR)

.PHONY: all clean