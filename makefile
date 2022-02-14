EXECUTABLE_NAME := Tetris

BIN_DIR := bin
COMPILER_FLAGS := -c
ASSEMBLER_FLAGS := -f elf64
LINKER_FLAGS := -no-pie

# find c and asm files
SOURCE_FILES := $(shell find -name "*.asm" -or -name "*.c")
# replace .c and .asm extensions with .o
RAW_OBJECTS := $(patsubst %.c, %.o, $(patsubst %.asm, %.o, $(SOURCE_FILES)))
# move object files to bin directory
OBJECTS := $(patsubst ./%, $(BIN_DIR)/%, $(RAW_OBJECTS))

# link obj files to executable (gcc)
Tetris: $(OBJECTS)
	gcc $(LINKER_FLAGS) $^ -o $(EXECUTABLE_NAME)

# c to obj (gcc)
bin/%.o: %.c $(BIN_DIR)
	gcc $(COMPILER_FLAGS) $< -o $@

# asm to obj (nasm)
bin/%.o: %.asm $(BIN_DIR)
	nasm $(ASSEMBLER_FLAGS) $< -o $@

# create bin directory if it's missing
$(BIN_DIR):
	mkdir $@