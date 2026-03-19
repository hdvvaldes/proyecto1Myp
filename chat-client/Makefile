
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
# NOTE Before using this def i need to generate flex
ALL_SRCS := $(wildcard $(SRC_DIR)/*.cpp)

# -- Object files
OBJS := $(patsubst $(SRC_DIR)/%.cpp, $(BUILD_DIR)/%.o, $(SRCS))

# =========================
# Targets
# =========================

.PHONY: all flex clean distclean run help lexer

# Default goal
all: $(TARGET)

# --- Link ----
$(TARGET): $(OBJS)
	@echo "LINKING FOR $@"
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
	@echo "Cleaning artefacts"
	rm -rf $(BUILD_DIR) $(TARGET) $(TEST_TARGET)

# The define clangd needs to match the selected lexer back-end
LEXER_DEFINE := -DUSE_FLEX_LEXER

# Flags that every translation unit sees (mirrors CXXFLAGS, minus -O/-g)
CLANGD_FLAGS := $(CXXFLAGS) $(LEXER_DEFINE)

lexer:
	flex++ lexer/chat_lexer.ll
	g++ lex.yy.cc -o lexerScan


compile_flags:
	@echo "$(CLANGD_FLAGS)" > compile_flags.txt
	@echo "Generated compile_flags.txt with flags: $(CLANGD_FLAGS)"
