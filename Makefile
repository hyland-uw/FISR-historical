# Compiler settings for M1 Mac with Clang and OpenMP
CC = /opt/homebrew/opt/llvm/bin/clang
CFLAGS = -Wall -Wextra -O3 -fopenmp -I/opt/homebrew/opt/libomp/include
LDFLAGS = -L/opt/homebrew/opt/libomp/lib -lomp

# Directories
SRC_DIR = src
BIN_DIR = bin
DATA_DIR = data

# List of source files
SOURCES = enumerated.c deconstructed.c approximated.c sliced.c optimized.c extracted.c narrowed.c binned.c

# Utility file to be compiled with each source
UTILS = utils.c

# Generate names for executables and data files
EXECUTABLES = $(SOURCES:%.c=$(BIN_DIR)/%)
DATA_FILES = $(SOURCES:%.c=$(DATA_DIR)/%.csv)

# Header files
HEADERS = $(wildcard $(SRC_DIR)/*.h)

# Default target
all: $(EXECUTABLES) $(DATA_FILES)

# Rule to compile source files with utils.c
$(BIN_DIR)/%: $(SRC_DIR)/%.c $(SRC_DIR)/$(UTILS) $(HEADERS)
	@mkdir -p $(BIN_DIR)
	$(CC) $(CFLAGS) $< $(SRC_DIR)/$(UTILS) -o $@

# Ensure all executables are recompiled if any header changes
$(EXECUTABLES): $(HEADERS)

# Rule to run executables and generate data files
$(DATA_DIR)/%.csv: $(BIN_DIR)/%
	@mkdir -p $(DATA_DIR)
	./$< > $@

# Clean up build artifacts
clean:
	rm -rf $(BIN_DIR) $(DATA_DIR)

.PHONY: all clean
