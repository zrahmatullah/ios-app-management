.PHONY: all core test clean xcode help

# Target framework output directory
FRAMEWORK_DIR = ios/Frameworks
FRAMEWORK_NAME = LuminaCore.xcframework

help:
	@echo "Lumina Build Commands:"
	@echo "  make core     - Build Go core as iOS XCFramework using gomobile"
	@echo "  make test     - Run Go unit tests for financial & savings logic"
	@echo "  make xcode    - Open Xcode project"
	@echo "  make clean    - Remove build artifacts"

test:
	cd core && go test -v ./tests/...

core:
	@echo "==> Ensuring gomobile is installed..."
	go install golang.org/x/mobile/cmd/gomobile@latest
	go install golang.org/x/mobile/cmd/gobind@latest
	gomobile init
	@echo "==> Creating Frameworks directory..."
	mkdir -p $(FRAMEWORK_DIR)
	@echo "==> Compiling Go core into $(FRAMEWORK_NAME)..."
	cd core && gomobile bind -target=ios,iossimulator -o ../$(FRAMEWORK_DIR)/$(FRAMEWORK_NAME) ./bridge
	@echo "==> Build successful: $(FRAMEWORK_DIR)/$(FRAMEWORK_NAME)"

xcode:
	open ios/Lumina.xcodeproj

clean:
	rm -rf $(FRAMEWORK_DIR)/$(FRAMEWORK_NAME)
