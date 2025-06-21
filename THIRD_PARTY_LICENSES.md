# Third-Party Licenses and Attributions

Zishu uses the following third-party resources and libraries. We are grateful to all the developers and organizations who have made their work available.

## MakeMeAHanzi

**Source**: https://github.com/skishore/makemeahanzi  
**Copyright**: Copyright (c) 2016 Shaunak Kishore  
**License**: GNU Lesser General Public License v3.0 (LGPL-3.0)

MakeMeAHanzi provides the stroke order data that powers Zishu's character writing validation. This includes:
- SVG path data for each stroke
- Median points for stroke validation
- Character decomposition information

### LGPL-3.0 License Summary
This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

The complete LGPL-3.0 license text can be found at: https://www.gnu.org/licenses/lgpl-3.0.html

## CC-CEDICT

**Source**: https://cc-cedict.org/  
**Copyright**: Copyright (c) 2024 MDBG  
**License**: Creative Commons Attribution-ShareAlike 4.0 International License (CC BY-SA 4.0)

CC-CEDICT provides Chinese-English dictionary entries used in Zishu for character definitions and pinyin romanization.

### CC BY-SA 4.0 License Summary
This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License. You are free to:
- Share — copy and redistribute the material in any medium or format
- Adapt — remix, transform, and build upon the material for any purpose, even commercially

Under the following terms:
- Attribution — You must give appropriate credit
- ShareAlike — If you remix, transform, or build upon the material, you must distribute your contributions under the same license

The complete CC BY-SA 4.0 license text can be found at: https://creativecommons.org/licenses/by-sa/4.0/legalcode

## Unicode Unihan Database

**Source**: https://unicode.org/charts/unihan.html  
**Copyright**: Copyright (c) 1991-2024 Unicode, Inc.  
**License**: Unicode License Agreement

The Unicode Unihan Database provides comprehensive information about CJK ideographs, including:
- Character properties
- Radical and stroke count information
- Cross-references between character variants

### Unicode License Agreement
The Unicode Data Files are provided as-is by Unicode, Inc. No claims are made as to fitness for any particular purpose. No warranties of any kind are expressed or implied.

For the complete Unicode License Agreement, see: https://www.unicode.org/license.txt

## Flutter Framework

**Source**: https://flutter.dev/  
**Copyright**: Copyright 2014 The Flutter Authors  
**License**: BSD 3-Clause License

Flutter is the UI framework used to build Zishu.

## Flutter Dependencies

The following Flutter/Dart packages are used in Zishu:

### shared_preferences
**License**: BSD 3-Clause  
**Purpose**: Local data storage for user preferences

### uuid
**License**: MIT License  
**Purpose**: Generating unique identifiers

### sqflite
**License**: MIT License  
**Purpose**: SQLite database support (currently unused but included)

### path & path_provider
**License**: BSD 3-Clause  
**Purpose**: File system path manipulation

### file_picker
**License**: MIT License  
**Purpose**: File selection for import/export features

### url_launcher
**License**: BSD 3-Clause  
**Purpose**: Opening external links

---

## Acknowledgments

We would like to express our sincere gratitude to:

1. **Shaunak Kishore** and the MakeMeAHanzi project for providing high-quality, open-source stroke order data that makes accurate character validation possible.

2. **The MDBG team** for maintaining CC-CEDICT, a comprehensive Chinese-English dictionary that enriches our app with definitions and pronunciations.

3. **The Unicode Consortium** for their extensive work in standardizing Chinese characters and providing the Unihan database.

4. **The Flutter team and community** for creating an excellent cross-platform framework.

5. **All contributors** to the open-source packages we use.

Without these projects, Zishu would not be possible. Their commitment to open data and open source software benefits learners of Chinese worldwide.

---

If you believe we have missed any attribution or have concerns about our use of third-party resources, please contact us through our GitHub repository.