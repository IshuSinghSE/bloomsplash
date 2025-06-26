#!/bin/bash

# Interactive release script for Flutter project
# This script will guide you through version bump, changelog update, git operations, and GitHub release.
# Each step will be explained in detail before execution.

set -e

# Function to prompt user for yes/no with explanation
yes_no() {
    echo
    while true; do
        read -p "$1 [y/n]: " yn
        case $yn in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "Please answer yes or no.";;
        esac
    done
}

# Get current version from pubspec.yaml
CUR_VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
echo "Current version: $CUR_VERSION"
echo "This script will help you create a new release."
read -p "Enter new version (e.g., 0.1.4): " NEW_VERSION

if [[ -z "$NEW_VERSION" ]]; then
    echo "No version entered. Exiting."
    exit 1
fi

echo
cat <<EOM
Updating pubspec.yaml version
----------------------------
This will update the version field in pubspec.yaml from $CUR_VERSION to $NEW_VERSION.
EOM

# Track which steps were performed
SUMMARY="\nRelease Summary:\n"

yes_no "Proceed with updating pubspec.yaml?" && {
    sed -i "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml
    echo "pubspec.yaml updated."
    SUMMARY+="- pubspec.yaml updated to $NEW_VERSION\n"
}

echo
cat <<EOM
Updating CHANGELOG.md
--------------------
This will add a new section for version $NEW_VERSION in CHANGELOG.md with today's date.
You should edit the changelog later to fill in the details for this release.
EOM

yes_no "Update CHANGELOG.md for version $NEW_VERSION?" && {
    DATE=$(date +%Y-%m-%d)
    sed -i "/## \[Unreleased\]/a \
\n## [$NEW_VERSION] - $DATE\n### Added\n- ...\n\n### Changed\n- ...\n\n### Deprecated\n- ...\n\n### Removed\n- ...\n\n### Fixed\n- ...\n\n### Security\n- ...\n" CHANGELOG.md
    echo "CHANGELOG.md updated."
    SUMMARY+="- CHANGELOG.md updated for $NEW_VERSION\n"
}

echo
cat <<EOM
Creating release branch
----------------------
This will create a new branch named release/v$NEW_VERSION from your current branch.
EOM

yes_no "Create release branch release/v$NEW_VERSION?" && {
    git checkout -b release/v$NEW_VERSION
    echo "Branch release/v$NEW_VERSION created."
    SUMMARY+="- Created branch release/v$NEW_VERSION\n"
}

echo
cat <<EOM
Committing and pushing changes
-----------------------------
This will commit the version and changelog changes, and push the release branch to origin.
EOM

yes_no "Commit and push changes?" && {
    git add pubspec.yaml CHANGELOG.md
    git commit -m "chore: release v$NEW_VERSION"
    git push --set-upstream origin release/v$NEW_VERSION
    echo "Changes committed and pushed."
    SUMMARY+="- Committed and pushed changes to release/v$NEW_VERSION\n"
}

echo
cat <<EOM
Tagging the release
------------------
This will create a git tag v$NEW_VERSION and push it to origin.
EOM

yes_no "Tag the release as v$NEW_VERSION?" && {
    git tag v$NEW_VERSION
    git push origin v$NEW_VERSION
    echo "Tag v$NEW_VERSION created and pushed."
    SUMMARY+="- Tagged release as v$NEW_VERSION and pushed tag\n"
}

echo
cat <<EOM
Building Flutter APKs
--------------------
This will clean previous builds and build release APKs for Android (universal, arm64-v8a, and armeabi-v7a).
This step is required before creating the GitHub release with APK uploads.

Note: Building APKs can take several minutes. If you have recent APKs and just want to 
upload them, you can skip building and go directly to the GitHub release step.
EOM

BUILD_APKS=false
yes_no "Build Flutter APKs for release?" && {
    BUILD_APKS=true
    echo "Cleaning previous builds..."
    flutter clean
    echo "Getting dependencies..."
    flutter pub get
    echo "Building Flutter APKs..."
    flutter build apk --release --split-per-abi
    echo "APKs built successfully."
    
    # Verify APKs were created
    APK_DIR="build/app/outputs/flutter-apk"
    if [[ -f "$APK_DIR/app-release.apk" ]]; then
        echo "✓ Universal APK created: $(du -h $APK_DIR/app-release.apk | cut -f1)"
    fi
    if [[ -f "$APK_DIR/app-arm64-v8a-release.apk" ]]; then
        echo "✓ ARM64 APK created: $(du -h $APK_DIR/app-arm64-v8a-release.apk | cut -f1)"
    fi
    if [[ -f "$APK_DIR/app-armeabi-v7a-release.apk" ]]; then
        echo "✓ ARM32 APK created: $(du -h $APK_DIR/app-armeabi-v7a-release.apk | cut -f1)"
    fi
    
    SUMMARY+="- Built Flutter APKs for release\n"
} || {
    echo "Skipping APK build. Will use existing APKs if available."
}

echo
cat <<EOM
Creating GitHub release with APKs
--------------------------------
This will use the GitHub CLI to create a release for v$NEW_VERSION and upload the APK files.
The following APKs will be uploaded (if they exist):
- app-release.apk (universal)
- app-arm64-v8a-release.apk (ARM 64-bit)
- app-armeabi-v7a-release.apk (ARM 32-bit)
EOM

yes_no "Create GitHub release with APK uploads?" && {
    # Check if APK files exist
    APK_DIR="build/app/outputs/flutter-apk"
    UNIVERSAL_APK="$APK_DIR/app-release.apk"
    ARM64_APK="$APK_DIR/app-arm64-v8a-release.apk"
    ARM32_APK="$APK_DIR/app-armeabi-v7a-release.apk"
    
    # Check which APKs are available
    APKS_TO_UPLOAD=()
    if [[ -f "$UNIVERSAL_APK" ]]; then
        APKS_TO_UPLOAD+=("$UNIVERSAL_APK")
        echo "✓ Found universal APK: $(du -h $UNIVERSAL_APK | cut -f1)"
    fi
    if [[ -f "$ARM64_APK" ]]; then
        APKS_TO_UPLOAD+=("$ARM64_APK")
        echo "✓ Found ARM64 APK: $(du -h $ARM64_APK | cut -f1)"
    fi
    if [[ -f "$ARM32_APK" ]]; then
        APKS_TO_UPLOAD+=("$ARM32_APK")
        echo "✓ Found ARM32 APK: $(du -h $ARM32_APK | cut -f1)"
    fi
    
    if [[ ${#APKS_TO_UPLOAD[@]} -gt 0 ]]; then
        echo "Uploading ${#APKS_TO_UPLOAD[@]} APK(s) to GitHub release..."
        gh release create v$NEW_VERSION \
            "${APKS_TO_UPLOAD[@]}" \
            --title "v$NEW_VERSION" \
            --notes "See CHANGELOG.md for details."
        echo "GitHub release created with ${#APKS_TO_UPLOAD[@]} APK upload(s)."
        SUMMARY+="- GitHub release created for v$NEW_VERSION with ${#APKS_TO_UPLOAD[@]} APK(s)\n"
    else
        echo "Warning: No APK files found. Creating release without APKs."
        echo "You may want to build APKs first or upload them manually later."
        
        yes_no "Create release without APKs?" && {
            gh release create v$NEW_VERSION \
                --title "v$NEW_VERSION" \
                --notes "See CHANGELOG.md for details."
            echo "GitHub release created without APKs."
            SUMMARY+="- GitHub release created for v$NEW_VERSION (no APKs)\n"
        } || {
            echo "Skipping GitHub release creation."
            SUMMARY+="- Skipped GitHub release creation\n"
        }
    fi
}

echo
cat <<EOM
Merging release branch to main
-----------------------------
This will merge release/v$NEW_VERSION into main, after pulling the latest main branch.
EOM

yes_no "Merge release/v$NEW_VERSION to main?" && {
    git checkout main
    git pull origin main
    git merge --no-ff release/v$NEW_VERSION
    git push origin main
    echo "release/v$NEW_VERSION merged to main and pushed."
    SUMMARY+="- Merged release/v$NEW_VERSION to main and pushed\n"
}

echo
cat <<EOM
All done!
---------
Release process complete. Please review your repository and GitHub release page.
EOM

echo -e "$SUMMARY"
#!/bin/bash

# Interactive release script for Flutter project
# This script will guide you through version bump, changelog update, git operations, and GitHub release.
# Each step will be explained in detail before execution.

set -e

# Function to prompt user for yes/no with explanation
yes_no() {
    echo
    while true; do
        read -p "$1 [y/n]: " yn
        case $yn in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "Please answer yes or no.";;
        esac
    done
}

# Get current version from pubspec.yaml
CUR_VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
echo "Current version: $CUR_VERSION"
echo "This script will help you create a new release."
read -p "Enter new version (e.g., 0.1.4): " NEW_VERSION

if [[ -z "$NEW_VERSION" ]]; then
    echo "No version entered. Exiting."
    exit 1
fi

echo
cat <<EOM
Updating pubspec.yaml version
----------------------------
This will update the version field in pubspec.yaml from $CUR_VERSION to $NEW_VERSION.
EOM

# Track which steps were performed
SUMMARY="\nRelease Summary:\n"

yes_no "Proceed with updating pubspec.yaml?" && {
    sed -i "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml
    echo "pubspec.yaml updated."
    SUMMARY+="- pubspec.yaml updated to $NEW_VERSION\n"
}

echo
cat <<EOM
Updating CHANGELOG.md
--------------------
This will add a new section for version $NEW_VERSION in CHANGELOG.md with today's date.
You should edit the changelog later to fill in the details for this release.
EOM

yes_no "Update CHANGELOG.md for version $NEW_VERSION?" && {
    DATE=$(date +%Y-%m-%d)
    sed -i "/## \[Unreleased\]/a \
\n## [$NEW_VERSION] - $DATE\n### Added\n- ...\n\n### Changed\n- ...\n\n### Deprecated\n- ...\n\n### Removed\n- ...\n\n### Fixed\n- ...\n\n### Security\n- ...\n" CHANGELOG.md
    echo "CHANGELOG.md updated."
    SUMMARY+="- CHANGELOG.md updated for $NEW_VERSION\n"
}

echo
cat <<EOM
Creating release branch
----------------------
This will create a new branch named release/v$NEW_VERSION from your current branch.
EOM

yes_no "Create release branch release/v$NEW_VERSION?" && {
    git checkout -b release/v$NEW_VERSION
    echo "Branch release/v$NEW_VERSION created."
    SUMMARY+="- Created branch release/v$NEW_VERSION\n"
}

echo
cat <<EOM
Committing and pushing changes
-----------------------------
This will commit the version and changelog changes, and push the release branch to origin.
EOM

yes_no "Commit and push changes?" && {
    git add pubspec.yaml CHANGELOG.md
    git commit -m "chore: release v$NEW_VERSION"
    git push --set-upstream origin release/v$NEW_VERSION
    echo "Changes committed and pushed."
    SUMMARY+="- Committed and pushed changes to release/v$NEW_VERSION\n"
}

echo
cat <<EOM
Tagging the release
------------------
This will create a git tag v$NEW_VERSION and push it to origin.
EOM

yes_no "Tag the release as v$NEW_VERSION?" && {
    git tag v$NEW_VERSION
    git push origin v$NEW_VERSION
    echo "Tag v$NEW_VERSION created and pushed."
    SUMMARY+="- Tagged release as v$NEW_VERSION and pushed tag\n"
}

echo
cat <<EOM
Creating GitHub release
----------------------
This will use the GitHub CLI to create a release for v$NEW_VERSION and upload the tag.
You can edit the release notes on GitHub later if needed.
EOM

yes_no "Create GitHub release with 'gh release create'?" && {
    gh release create v$NEW_VERSION --title "v$NEW_VERSION" --notes "See CHANGELOG.md for details."
    echo "GitHub release created."
    SUMMARY+="- GitHub release created for v$NEW_VERSION\n"
}

echo
cat <<EOM
Merging release branch to main
-----------------------------
This will merge release/v$NEW_VERSION into main, after pulling the latest main branch.
EOM

yes_no "Merge release/v$NEW_VERSION to main?" && {
    git checkout main
    git pull origin main
    git merge --no-ff release/v$NEW_VERSION
    git push origin main
    echo "release/v$NEW_VERSION merged to main and pushed."
    SUMMARY+="- Merged release/v$NEW_VERSION to main and pushed\n"
}

echo
cat <<EOM
All done!
---------
Release process complete. Please review your repository and GitHub release page.
EOM

echo -e "$SUMMARY"
