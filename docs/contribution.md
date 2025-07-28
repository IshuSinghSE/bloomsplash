# Contributing to BloomSplash

Thank you for your interest in contributing to BloomSplash! We welcome high-quality contributions that help improve the app and its experience for users.

---

## 🚦 Quick Start

1. **Fork the repository** and clone your fork.
2. **Create a new branch** for your feature or fix.
3. **Make your changes** following our architecture and code style.
4. **Test your changes** locally.
5. **Submit a pull request** with a clear description to `develop`.

---

## 🛠️ What Can You Contribute?
- New wallpaper collections (original, high-quality only)
- UI/UX improvements
- Bug fixes and performance enhancements
- Feature suggestions and implementation
- Documentation updates

---

## 🧩 Project Structure & Conventions
- **Modular code:** Organize features in `lib/features/`, shared utilities in `lib/core/`, and app-specific logic in `lib/app/`.
- **Model serialization:** All models must implement `toJson`/`fromJson`.
- **Centralized routing:** Use `app/routes/app_routes.dart` for navigation.
- **No app-specific logic in `core/`.**
- **Use export files** for centralized imports.

See `.github/copilot-instructions.md` and `README.md` for more details.

---

## 🧪 Testing
- Run tests with `flutter test` for Dart/Flutter code.
- For backend/Java, use `mvn -B test`.
- Add or update tests for any new features or bug fixes.

---

## 📦 Submitting Wallpapers
- Only submit original, high-quality wallpapers.
- Do not upload copyrighted or low-resolution images.
- Collections should be organized and tagged appropriately.

---

## 💬 Communication
- For major changes, open an issue first to discuss your proposal.
- Be respectful and constructive in all interactions.
- For questions, contact Ishu Singh: [ishu.111636@gmail.com](mailto:ishu.111636@gmail.com)

---

## 📝 License & Credits
- By contributing, you agree to license your work under the project's LICENSE.
- See LICENSE for details.

---

Thank you for helping make BloomSplash better!
