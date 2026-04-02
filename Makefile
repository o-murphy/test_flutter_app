.PHONY: native ffigen test format clean

# Cross-platform helpers
ifeq ($(OS),Windows_NT)
  NPROC   := $(NUMBER_OF_PROCESSORS)
  RM_DIR  := cmake -E remove_directory
else
  NPROC   := $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
  RM_DIR  := rm -rf
endif

# Build the native shared library via CMake
native:
	cmake -S external/bclibc -B build/bclibc -DCMAKE_BUILD_TYPE=Release
	cmake --build build/bclibc --parallel $(NPROC)

# Re-generate Dart FFI bindings from the C header
# Requires LLVM/Clang installed:
#   Windows: winget install LLVM  (then restart terminal)
#   Linux:   sudo apt install libclang-dev clang
#   macOS:   brew install llvm
ffigen:
	dart run ffigen --config ffigen.yaml

# Run all tests (native must be built first)
test: native
	flutter analyze && flutter test 2>&1

format:
	dart format lib/ && dart format test/

run:
	flutter run

run-clean:
	rm -rf ~/.eBalistyka && flutter run

# Run only unit tests (no native dependency)
unit:
	dart test test/core/solver/unit_test.dart

clean:
	$(RM_DIR) build/bclibc
