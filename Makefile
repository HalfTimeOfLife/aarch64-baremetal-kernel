CROSS = aarch64-none-elf

CC = $(CROSS)-gcc
LD = $(CROSS)-ld

LD_CUSTOM = linker.ld

SRC_S := $(wildcard src/*/*.s)
SRC_C := $(wildcard src/*/*.c)
OUTPUT_DIR := build
OBJ := $(patsubst src/%.s,$(OUTPUT_DIR)/%.o,$(SRC_S)) \
	$(patsubst src/%.c,$(OUTPUT_DIR)/%.o,$(SRC_C))
OUTPUT := $(OUTPUT_DIR)/kernel.elf

all: $(OUTPUT)

$(OUTPUT): $(OBJ) $(LD_CUSTOM)
	mkdir -p $(@D)
	$(LD) -T $(LD_CUSTOM) -o $@ $(OBJ)

$(OUTPUT_DIR)/%.o: src/%.s
	mkdir -p $(@D)
	$(CC) -c $< -o $@

$(OUTPUT_DIR)/%.o: src/%.c
	mkdir -p $(@D)
	$(CC) -c $< -o $@

clean:
	rm -rf $(OUTPUT_DIR)

.PHONY: all clean