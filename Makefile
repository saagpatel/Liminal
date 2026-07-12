.PHONY: build test release verify-release-shape verify open clean

PROJECT := Liminal.xcodeproj
SCHEME := Liminal
DESTINATION ?= platform=iOS Simulator,name=iPhone 17
DERIVED_DATA ?= .build/DerivedData
RELEASE_DIR ?= $(CURDIR)/builds/Release-iphoneos

build:
	xcodebuild build \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-destination '$(DESTINATION)' \
		-derivedDataPath "$(DERIVED_DATA)"

test:
	xcodebuild test \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-destination '$(DESTINATION)' \
		-derivedDataPath "$(DERIVED_DATA)"

release:
	mkdir -p builds
	xcodebuild build \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-configuration Release \
		-destination 'generic/platform=iOS' \
		-derivedDataPath "$(DERIVED_DATA)" \
		CONFIGURATION_BUILD_DIR="$(RELEASE_DIR)" \
		CODE_SIGNING_ALLOWED=NO

verify-release-shape: release
	sh scripts/verify_release_bundle.sh "$(RELEASE_DIR)/Liminal.app"

verify: test verify-release-shape

open:
	open "$(PROJECT)"

clean:
	rm -rf .build builds
