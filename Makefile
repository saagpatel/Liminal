.PHONY: generate build test release verify-release-shape verify-playtest-packet archive export-app-store verify open clean

PROJECT := Liminal.xcodeproj
SCHEME := Liminal
DESTINATION ?= platform=iOS Simulator,name=iPhone 17
DERIVED_DATA ?= .build/DerivedData
RELEASE_DIR ?= $(CURDIR)/builds/Release-iphoneos
ARCHIVE_PATH ?= $(CURDIR)/builds/Liminal.xcarchive
EXPORT_PATH ?= $(CURDIR)/builds/AppStore
PROVISIONING_UPDATE_FLAG ?=

generate:
	xcodegen generate

build: generate
	xcodebuild build \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-destination '$(DESTINATION)' \
		-derivedDataPath "$(DERIVED_DATA)"

test: generate
	xcodebuild test \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-destination '$(DESTINATION)' \
		-derivedDataPath "$(DERIVED_DATA)"

release: generate
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

verify-playtest-packet:
	sh scripts/verify_playtest_packet.sh

verify: test verify-release-shape verify-playtest-packet

archive: generate
	xcodebuild archive \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-configuration Release \
		-destination 'generic/platform=iOS' \
		-archivePath "$(ARCHIVE_PATH)"

export-app-store: archive
	xcodebuild -exportArchive \
		-archivePath "$(ARCHIVE_PATH)" \
		-exportPath "$(EXPORT_PATH)" \
		-exportOptionsPlist ExportOptions.plist \
		$(PROVISIONING_UPDATE_FLAG)

open:
	open "$(PROJECT)"

clean:
	rm -rf .build builds
