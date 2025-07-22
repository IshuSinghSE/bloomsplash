# v0.1.4 (2025-07-03)
## Minor Release

### Fixed / Improved
- Smoother wallpaper card overlay animation (slide only)
- Fixed text overflow and flicker in wallpaper cards
- Improved feedback form state persistence and screenshot handling
- Enhanced pagination and pull-to-refresh in explore page
- Fixed favorite button state sync and error messages
- Improved offline wallpaper viewing and image caching

### Technical
- Refactored Firebase service layer for better error handling
- Optimized memory usage and image lazy loading
- Improved pagination and refresh logic

---
# Changelog

All notable changes to this project will be documented in this file.

This project follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

n## [v0.1.8] - 2025-07-13
### Added
- Downloads details in wallpaper view
- Explicit license added to protect the app

### Changed
- Improved favorite button look (colored icon, better feedback)

### Fixed
- Guest logging issue (guests now handled correctly)

### Security
- License enforcement and protection

## [Unreleased]
n## [0.1.5] - 2025-07-04
### Added
- ...

### Changed
- ...

### Deprecated
- ...

### Removed
- ...

### Fixed
- ...

### Security
- ...

- Initial project setup
- Analytics feature merged from analytics branch

## [v0.1.3] - 2025-06-26
- Added: Analytics feature

## [v0.2.0] - 2025-07-20
### Added
- Firebase Cloud Messaging (FCM) integration for new wallpaper notifications
- Native system notifications using flutter_local_notifications
- Notification tap navigates to Explore page and triggers refresh
- Background notification analytics logging
- Improved adaptive and monochrome launcher icons

### Changed
- Notification icon and app icon updated for better visibility
- Gradle build updated to enable core library desugaring
- Refined notification workflow and icon usage

### Fixed
- Notification delivery and tap handling in foreground/background
- Icon rendering issues for monochrome and notification icons

### Security
- Updated dependencies for improved security and compatibility