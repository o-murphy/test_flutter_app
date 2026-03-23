.PHONY: native ffigen test clean

# Build the native shared library via CMake
native:
	cmake -S external/bclibc -B build/bclibc -DCMAKE_BUILD_TYPE=Release
	cmake --build build/bclibc -j$$(nproc)

# Re-generate Dart FFI bindings from the C header
ffigen:
	dart run ffigen --config ffigen.yaml

# Run all tests (native must be built first)
test: native
	dart test test/ffi_test.dart

# Run only unit tests (no native dependency)
unit:
	dart test test/unit_test.dart

clean:
	rm -rf build/bclibc
