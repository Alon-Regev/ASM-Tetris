EXECUTABLE_NAME := Tetris

BIN_DIR := bin
COMPILER_FLAGS := -c
ASSEMBLER_FLAGS := -f elf64
LINKER_FLAGS := -no-pie -lX11

# find c and asm files
SOURCE_FILES := $(shell find -name "*.asm" -or -name "*.c")
# replace .c and .asm extensions with .o
RAW_OBJECTS := $(patsubst %.c, %.o, $(patsubst %.asm, %.o, $(SOURCE_FILES)))
# move object files to bin directory
OBJECTS := $(patsubst ./%, $(BIN_DIR)/%, $(RAW_OBJECTS))

# link obj files to executable (gcc)
Tetris: $(OBJECTS)
	@gcc $^ -o $(EXECUTABLE_NAME) $(LINKER_FLAGS)

# c to obj (gcc)
bin/%.o: %.c $(BIN_DIR)
	@gcc $< -o $@ $(COMPILER_FLAGS)

# asm to obj (nasm)
bin/%.o: %.asm $(BIN_DIR)
	@nasm $< -o $@ $(ASSEMBLER_FLAGS)

# create bin directory if it's missing
$(BIN_DIR):
	@mkdir $@

# compile and run
.PHONY: run
run: $(EXECUTABLE_NAME)
	@./$(EXECUTABLE_NAME)