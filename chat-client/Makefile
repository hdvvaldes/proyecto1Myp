
# -- Project name ---
TARGET  := chat-client

# -- Directories ----
SRC_DIR   := src
INC_DIR   := include
LEX_DIR   := lexer
BUILD_DIR := build

# -- Compiler Definitions ------
CXX      := g++
CXXFLAGS := -std=c++17 -Wall -Wextra -Wpedantic \
             -I$(INC_DIR) \
             -pthread
LDFLAGS  := -pthread

# -- Lexer Definitions ---

GENERATED_LEXER := $(SRC_DIR)/Lexer.cpp
LEX_SRC         := $(LEX_DIR)/chat_lexer.ll
LEXER_SRC       := $(GENERATED_LEXER)
CXXFLAGS        += -DUSE_FLEX_LEXER
# flex++ requires -lfl on some systems; try to link it if available
FL_LIB          := $(shell $(CXX) -lfl -x c++ /dev/null -o /dev/null 2>/dev/null && echo "-lfl")
LDFLAGS         += $(FL_LIB)

# -- Source files ----
ALL_SRCS := $(wildcard $(SRC_DIR)/*.cpp)

SRCS := $(ALL_SRCS) $(LEXER_SRC)

# -- Object files
OBJS := $(patsubst $(SRC_DIR)/%.cpp, $(BUILD_DIR)/%.o, $(SRCS))

DEPS := $(OBJS:.o=.d)

# =========================
# Targets
# =========================

.PHONY: all flex clean distclean run help

# Default goal
all: $(TARGET)

# --- Link ----
$(TARGET): $(OBJS)
	@echo "LINKING FOR $@"
	@echo "Object $^"
	$(CXX) $(CXXFLAGS) $^ -o $@ $(LDFLAGS)
	@echo "Build complete: $(TARGET)"

# -- Compile for object files --
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp | $(BUILD_DIR)
	@echo "COMPILING $<"
	$(CXX) $(CXXFLAGS) -MMD -MP -c $< -o $@

# -- Building lexer --
$(GENERATED_LEXER): $(LEX_SRC)
	@echo "[flex++] Generating $@ from $<"
	flex++ -o $@ $<
	@echo "[flex++] Done."

# -- Create build directory --
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

-include $(DEPS)

# -- run --
run: all
	./$(TARGET)

# -- cleaning --
clean:
	@echo "Cleaning artifects"
	rm -rf $(BUILD_DIR) $(TARGET) $(TEST_TARGET) $(LEXER_SRC)

# Flags that every translation unit sees (mirrors CXXFLAGS)
CLANGD_FLAGS := $(CXXFLAGS)

compile_flags:
	@echo "$(CLANGD_FLAGS)" > compile_flags.txt
	@echo "Generated compile_flags.txt with flags: $(CLANGD_FLAGS)"
