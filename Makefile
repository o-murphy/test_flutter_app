.PHONY: native ffigen test format clean

# Build the native shared library via CMake
native:
	cmake -S external/bclibc -B build/bclibc -DCMAKE_BUILD_TYPE=Release
	cmake --build build/bclibc -j$$(nproc)

# Re-generate Dart FFI bindings from the C header
ffigen:
	dart run ffigen --config ffigen.yaml

# Run all tests (native must be built first)
test: native
	flutter analyze && flutter test 2>&1

format:
	dart format lib/ && dart format test/

# Run only unit tests (no native dependency)
unit:
	dart test test/core/solver/unit_test.dart

clean:
	rm -rf build/bclibc
