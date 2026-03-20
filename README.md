# Zishu 字书

**Master Chinese character writing with stroke order guidance**

Zishu is an open-source Flutter mobile application that helps learners master Chinese character writing through interactive stroke-by-stroke practice. Using authentic data from the MakeMeAHanzi database, Zishu provides real-time stroke validation, visual feedback, and comprehensive progress tracking to make learning Chinese characters engaging and effective.

Whether you're a beginner starting with basic radicals or an advanced learner tackling HSK vocabulary, Zishu adapts to your learning pace with customizable practice sets, grouped study modes, and intelligent review systems.

## ✨ Features

- ✍️ **Stroke order** - Practice with real stroke data from MakeMeAHanzi, ensuring you learn the correct writing technique
- 📚 **Comprehensive character sets** - Pre-built sets including HSK levels 1-6, radicals, and frequency-based lists
- 🎯 **Custom practice sets** - Create your own character lists or import from text files and images via OCR
- 📊 **Progress tracking** - Monitor your learning with daily streaks, goal setting, and detailed statistics
- 🔄 **Spaced repetition** - Intelligent review system based on your performance
- 🗣️ **Audio pronunciation** - Hear native Mandarin pronunciation using text-to-speech
- 📖 **Built-in dictionary** - View definitions, pinyin, and example words from CC-CEDICT
- 🌍 **Multi-language support** - Interface available in English and Chinese
- 🎨 **Customizable experience** - Adjust brush styles, hint colors, practice modes, and more
- 📱 **Works offline** - All character data stored locally, no internet required

## 📲 Download

**iOS**: Available on the [App Store](https://apps.apple.com/us/app/zishu/id6747624319)

## 🛠️ Technology Stack

Built with **Flutter** and **Dart** for cross-platform native performance.

**Character data sources:**

- [MakeMeAHanzi](https://github.com/skishore/makemeahanzi) - Authentic stroke order and SVG path data (LGPL License)
- [CC-CEDICT](https://www.mdbg.net/chinese/dictionary?page=cc-cedict) - Comprehensive Chinese-English dictionary (CC BY-SA License)
- [Unicode Unihan Database](https://www.unicode.org/charts/unihan.html) - Character metadata and classifications

**Key dependencies:**

- `flutter_tts` - Text-to-speech for pronunciation
- `google_mlkit_text_recognition` - OCR for image import
- `sqflite` - Local database storage
- `shared_preferences` - User settings persistence

## 🤝 Contributing

Contributions are welcome! Zishu is open source under the GPL v3 license, which means you're free to:

- Use the code for personal or commercial projects
- Modify and adapt it to your needs
- Distribute your own versions (with source code)

**Before contributing:**

1. Open an issue to discuss your proposed changes
2. Fork the repository and create a feature branch
3. Follow the existing code style and architecture
4. Ensure all features work on both iOS and Android
5. Submit a pull request with a clear description

Please note that any contributions you make will be licensed under GPL v3.

## 📋 Building from Source

The build process id dependent on your operating system.

- [iOS](./docs/BUILDING_ON_IOS.md)
- [Windows or Linux](./docs/Building_ON_WINDOWS_AND_LINUX.md)

## 📄 License

This project is licensed under the **GNU General Public License v3.0** - see the [LICENSE](LICENSE) file for details.

This means:

- ✅ You can use, modify, and distribute this software
- ✅ You can use it for commercial purposes
- ⚠️ Any distributed modifications must also be open source under GPL v3
- ⚠️ You must include the source code when distributing
- ⚠️ You must state changes you make to the code

## 👤 Author

**Archer Morrison** ([@Grosess](https://github.com/Grosess))

Designed Zishu, coded by Claude AI.

## 🙏 Acknowledgments

Special thanks to:

- **Shaunak Kishore** for creating and maintaining [MakeMeAHanzi](https://github.com/skishore/makemeahanzi), which provides the stroke order data that makes this app possible
- **MDBG.net** for maintaining the [CC-CEDICT](https://www.mdbg.net/chinese/dictionary?page=cc-cedict) Chinese-English dictionary
- **Unicode Consortium** for the comprehensive [Unihan Database](https://www.unicode.org/charts/unihan.html)
- The Flutter community for excellent documentation and packages

## 📱 Privacy

Zishu respects your privacy:

- ✅ All data stored locally on your device
- ✅ No analytics or tracking
- ✅ No account required
- ✅ No internet connection needed (except for initial app download)

See [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for full details.

## 🐛 Issues & Support

Found a bug or have a feature request? Please [open an issue](https://github.com/Grosess/zishu/issues) on GitHub.
