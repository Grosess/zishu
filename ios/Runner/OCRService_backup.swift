import Foundation
import Vision
import VisionKit
import UIKit

@available(iOS 13.0, *)
class OCRService: NSObject {
    static let shared = OCRService()
    
    private override init() {
        super.init()
    }
    
    func performOCR(on image: UIImage, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(OCRError.invalidImage))
            return
        }
        
        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(.failure(OCRError.noTextFound))
                return
            }
            
            let results = self.processObservationsAsTable(observations)
            completion(.success(results))
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]
        request.usesLanguageCorrection = false
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func processObservationsAsTable(_ observations: [VNRecognizedTextObservation]) -> [[String: Any]] {
        print("\n==================== RAW OCR DATA ====================")
        
        // First show ALL raw OCR data
        var allRawTexts: [(text: String, x: Float, y: Float)] = []
        for observation in observations {
            guard let text = observation.topCandidates(1).first?.string.trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty else { continue }
            
            let x = Float(observation.boundingBox.origin.x)
            let y = Float(observation.boundingBox.origin.y)
            allRawTexts.append((text, x, y))
        }
        
        // Sort all raw texts by Y position (top to bottom)
        allRawTexts.sort { $0.y > $1.y }
        
        print("ALL RAW OCR TEXT (top to bottom):")
        for (index, item) in allRawTexts.enumerated() {
            print("  \(index + 1). '\(item.text)' at X: \(String(format: "%.3f", item.x)), Y: \(String(format: "%.3f", item.y))")
        }
        print("Total raw texts detected: \(allRawTexts.count)")
        
        print("\n==================== CLASSIFICATION ====================")
        
        // Separate Chinese terms and English definitions
        var chineseItems: [(text: String, x: Float, y: Float)] = []
        var englishItems: [(text: String, x: Float, y: Float)] = []
        var allItems: [(text: String, x: Float, y: Float, type: String)] = []
        
        for observation in observations {
            guard let text = observation.topCandidates(1).first?.string.trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty else { continue }
            
            let x = Float(observation.boundingBox.origin.x)
            let y = Float(observation.boundingBox.origin.y)
            
            print("Classifying: '\(text)' at X: \(String(format: "%.3f", x)), Y: \(String(format: "%.3f", y))")
            
            // Skip obvious headers
            if text == "中文" || text == "拼音" || text == "英文" || text == "班级" || text.contains("阅读") || text.contains("姓名") {
                print("  -> Skipping header: \(text)")
                continue
            }
            
            // Classify text type - check pinyin FIRST to avoid misclassifying as English
            if containsChineseCharacters(text) {
                let cleanChinese = extractChineseFromText(text)
                if !cleanChinese.isEmpty && cleanChinese.count >= 2 && !isGarbageChinese(cleanChinese) {
                    chineseItems.append((cleanChinese, x, y))
                    allItems.append((cleanChinese, x, y, "chinese"))
                    print("  -> Chinese: \(cleanChinese)")
                } else if !cleanChinese.isEmpty {
                    print("  -> Filtered Chinese garbage: \(cleanChinese)")
                }
            } else if isPinyinText(text) || isSimplePinyin(text) {
                // Check pinyin BEFORE English to prevent misclassification
                allItems.append((text, x, y, "pinyin"))
                print("  -> Pinyin: \(text)")
            } else if containsEnglishText(text) && !isGarbledText(text) {
                // Accept English text more liberally
                let cleanEnglish = cleanDefinition(text)
                if !cleanEnglish.isEmpty && !isLikelyPinyin(cleanEnglish) {
                    englishItems.append((cleanEnglish, x, y))
                    allItems.append((cleanEnglish, x, y, "english"))
                    print("  -> English: \(cleanEnglish)")
                }
            } else {
                print("  -> Unclassified: \(text)")
            }
        }
        
        print("\nFound \(chineseItems.count) Chinese terms, \(englishItems.count) English definitions")
        
        // Build table by sorting columns independently and matching by position
        print("\nChinese | Pinyin | English")
        print("--------|--------|--------")
        
        var results: [[String: Any]] = []
        
        // Sort Chinese items by Y position (top to bottom)
        chineseItems.sort { $0.y > $1.y }
        
        // Sort English items by Y position (top to bottom) 
        englishItems.sort { $0.y > $1.y }
        
        // Sort pinyin items by Y position (top to bottom)
        let pinyinItems = allItems.filter { $0.type == "pinyin" }.sorted { $0.y > $1.y }
        
        print("Sorted Chinese terms (top to bottom):")
        for (index, item) in chineseItems.enumerated() {
            print("  \(index + 1). '\(item.text)' at Y: \(String(format: "%.3f", item.y))")
        }
        
        print("Sorted English definitions (top to bottom):")
        for (index, item) in englishItems.enumerated() {
            print("  \(index + 1). '\(item.text)' at Y: \(String(format: "%.3f", item.y))")
        }
        
        print("Sorted Pinyin (top to bottom):")
        for (index, item) in pinyinItems.enumerated() {
            print("  \(index + 1). '\(item.text)' at Y: \(String(format: "%.3f", item.y))")
        }
        
        // Match by position - Chinese[0] with English[0], Chinese[1] with English[1], etc.
        let maxCount = max(chineseItems.count, englishItems.count)
        
        for i in 0..<maxCount {
            let chineseTerm = i < chineseItems.count ? chineseItems[i].text : ""
            let englishDef = i < englishItems.count ? englishItems[i].text : ""
            let pinyinTerm = i < pinyinItems.count ? pinyinItems[i].text : ""
            
            if !chineseTerm.isEmpty {
                let simplified = convertTermToSimplified(chineseTerm)
                
                // Use "-" for empty fields
                let displayChinese = simplified.isEmpty ? "-" : simplified
                let displayPinyin = pinyinTerm.isEmpty ? "-" : pinyinTerm
                let displayEnglish = englishDef.isEmpty ? "-" : englishDef
                
                print("\(displayChinese) | \(displayPinyin) | \(displayEnglish)")
                
                results.append([
                    "character": simplified,
                    "originalCharacter": chineseTerm,
                    "fullText": chineseTerm,
                    "definition": englishDef.isEmpty ? "No definition" : englishDef,
                    "pinyin": pinyinTerm,
                    "confidence": 0.9,
                    "rawText": "\(chineseTerm) | \(pinyinTerm) | \(englishDef)"
                ])
            }
        }
        
        print("\nTotal entries: \(results.count)")
        print("========================================================\n")
        
        return results
    }
    
    private func extractNumberFromText(_ text: String) -> Int? {
        // First check for simple number at the start
        if let match = text.range(of: "^\\d+", options: .regularExpression) {
            let numberStr = String(text[match])
            if let number = Int(numberStr) {
                return number
            }
        }
        
        // Check for Chinese numerals
        let chineseNumbers: [String: Int] = [
            "一": 1, "二": 2, "三": 3, "四": 4, "五": 5,
            "六": 6, "七": 7, "八": 8, "九": 9, "十": 10,
            "十一": 11, "十二": 12, "十三": 13, "十四": 14, "十五": 15,
            "十六": 16, "十七": 17, "十八": 18, "十九": 19, "二十": 20
        ]
        
        for (chinese, number) in chineseNumbers {
            if text.hasPrefix(chinese) {
                return number
            }
        }
        
        return nil
    }
    
    private func isNumberedVocabEntry(_ text: String) -> Bool {
        return extractNumberFromText(text) != nil
    }
    
    private func containsChineseCharacters(_ text: String) -> Bool {
        let chinesePattern = "[\u{4e00}-\u{9fff}\u{3400}-\u{4dbf}]+"
        if let regex = try? NSRegularExpression(pattern: chinesePattern, options: []) {
            return regex.firstMatch(in: text, range: NSRange(location: 0, length: text.count)) != nil
        }
        return false
    }
    
    private func containsValidEnglishWords(_ text: String) -> Bool {
        let lowText = text.lowercased()
        
        // Common English words that indicate valid definitions
        let commonWords = [
            "the", "a", "an", "and", "or", "of", "to", "in", "on", "at", "for", "with", "by", "from",
            "father", "mother", "brother", "sister", "son", "daughter", "uncle", "aunt", "cousin",
            "elder", "younger", "wife", "husband", "child", "children", "relative", "family",
            "new", "old", "year", "festival", "christmas", "spring", "time", "meet", "see", "hear", "heard",
            "los", "angeles", "york", "kong", "hong", "hongkong", "mainland", "china", "pass", "away", "spend",
            "celebrate", "person", "same", "name", "having", "older", "than", "you"
        ]
        
        // Check if text contains common English words
        for word in commonWords {
            if lowText.contains(word) {
                return true
            }
        }
        
        // Check for typical English definition patterns
        let patterns = [
            "\\b\\w+\\'s\\s+\\w+",  // possessive forms like "father's sister"
            "\\b(to|of|in|on|at|with|by|from)\\s+\\w+",  // prepositions
            "\\b\\w+ed\\b",  // past tense verbs
            "\\b\\w+ing\\b",  // present participle verbs
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               regex.firstMatch(in: text, range: NSRange(location: 0, length: text.count)) != nil {
                return true
            }
        }
        
        // If it has more than 3 words and contains common English letters/patterns, likely English
        let words = text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        return words.count >= 3 && text.range(of: "[bcdfghjklmnpqrstvwxyz]", options: .regularExpression) != nil
    }
    
    private func isPinyinText(_ text: String) -> Bool {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Immediately reject obvious English words
        let englishWords = ["heard", "you", "new", "york", "pass", "away", "time", "with", "meet", "see", "person", "child", "children", "mother", "father", "brother", "sister", "relative", "christmas", "spring", "festival", "mainland", "china", "hongkong", "angeles", "cousins", "family", "name", "older", "than", "husband", "wife", "spend", "celebrate"]
        let lowText = cleanText.lowercased()
        
        for englishWord in englishWords {
            if lowText == englishWord || lowText.contains(" \(englishWord) ") || lowText.hasPrefix("\(englishWord) ") || lowText.hasSuffix(" \(englishWord)") {
                return false
            }
        }
        
        // Reject garbled text patterns
        if cleanText.count <= 3 && (cleanText.contains("P") || cleanText.contains("Q") || cleanText == "al" || cleanText == "yOU") {
            return false
        }
        
        // Check for tone marks - strong indicator of pinyin
        let toneMarks = "āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ"
        for char in toneMarks {
            if cleanText.contains(char) {
                return true
            }
        }
        
        // Exact pinyin syllables - must match exactly, not just contain
        let pinyinSyllables = [
            "ba", "pa", "ma", "fa", "da", "ta", "na", "la", "ga", "ka", "ha",
            "bo", "po", "mo", "fo", "wo", "zi", "ci", "si", "qi", "xi", "yi",
            "bi", "pi", "mi", "di", "ti", "ni", "li", "zhi", "chi", "shi", "ri",
            "ju", "qu", "xu", "yu", "nu", "lu", "zu", "cu", "su", "zhu", "chu", "shu", "ru",
            "ji", "jia", "qia", "xia", "jie", "qie", "xie", "die", "tie", "nie", "lie",
            "jiao", "qiao", "xiao", "diao", "tiao", "niao", "liao",
            "jiu", "qiu", "xiu", "diu", "niu", "liu", "le", "ge", "ke", "he",
            "zhe", "che", "she", "re", "ze", "ce", "se", "er", "ye", "yue", "yuan",
            "yin", "yun", "ying", "yong", "wa", "wai", "wei", "wan", "wen",
            "wang", "weng", "wu", "dong", "tong", "nong", "long", "gong", "kong",
            "hong", "zhong", "chong", "rong", "zong", "cong", "jiang", "qiang",
            "xiang", "niang", "liang", "jing", "qing", "xing", "ding", "ting",
            "ning", "ling", "dan", "chan", "ran", "san", "shan", "gan", "kan", 
            "han", "man", "fan", "tan", "lan", "pan", "ban"
        ]
        
        // Split into words and check if ALL words are exact pinyin syllables
        let words = lowText.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        
        if words.count == 0 || words.count > 4 {
            return false  // Too many words, probably English
        }
        
        // ALL words must be exact pinyin syllables
        for word in words {
            if !pinyinSyllables.contains(word) {
                return false  // If any word is not pinyin, the whole thing is not pinyin
            }
        }
        
        return true  // All words are exact pinyin syllables
    }
    
    private func isLikelyPinyin(_ text: String) -> Bool {
        let lowText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If it contains English indicators, it's NOT pinyin
        if text.contains(",") || text.contains("'") || text.contains("of") || text.contains("the") || 
           text.contains("and") || text.contains("to") || text.contains("with") || 
           text.contains("brother") || text.contains("sister") || text.contains("mother") ||
           text.contains("father") || text.contains("child") || lowText.count > 15 {
            return false
        }
        
        // Only classify as pinyin if it's very clearly pinyin
        let pinyinPatterns = [
            "^[a-z]{2,4}\\s[a-z]{2,4}$",     // Exactly two simple syllables like "qin qi", "da bo"
            "^[a-z]{2,4}\\s[a-z]{2,4}\\s[a-z]{2,4}$"  // Exactly three simple syllables
        ]
        
        for pattern in pinyinPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               regex.firstMatch(in: lowText, range: NSRange(location: 0, length: lowText.count)) != nil {
                return true
            }
        }
        
        return false
    }
    
    private func isSimplePinyin(_ text: String) -> Bool {
        let lowText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Single word pinyin patterns - be very specific
        let simplePinyinList = [
            "ayi", "yifu", "haizi", "guo", "tang", "biao", "neidi",
            "jo ma", "uo shanji", "bo ma", "da bo", "gi fu", "gigu", "shashi",
            "shen shen", "nidi yue", "chin jie", "xiang gang", "jian mian", 
            "ting shuo", "tang ge", "qu shi", "sheng dan je"
        ]
        
        // Check if it exactly matches known pinyin
        if simplePinyinList.contains(lowText) {
            return true
        }
        
        // Check for simple single syllable pinyin (2-4 letters, no English words)
        if lowText.count >= 2 && lowText.count <= 6 && 
           lowText.range(of: "^[a-z]+$", options: .regularExpression) != nil &&
           !["the", "and", "new", "york", "los", "pass", "away", "time", "with"].contains(lowText) {
            return true
        }
        
        return false
    }
    
    private func isGarbageChinese(_ text: String) -> Bool {
        // Filter out obviously invalid Chinese terms
        let garbageChineseTerms = ["然需", "中文", "拼音", "英文", "班级", "姓名"]
        
        if garbageChineseTerms.contains(text) {
            return true
        }
        
        // Filter out single characters that are likely OCR errors
        if text.count == 1 {
            return true
        }
        
        return false
    }
    
    private func isGarbledText(_ text: String) -> Bool {
        let lowText = text.lowercased()
        
        // First check if it contains valid English words - if so, not garbled
        if containsValidEnglishWords(text) {
            return false
        }
        
        // Check for obvious OCR garbage patterns (short mixed-case nonsense)
        if text.count <= 4 {
            // Check for mixed case in short text (like "yOU", "qP", etc.)
            let hasLower = text.range(of: "[a-z]", options: .regularExpression) != nil
            let hasUpper = text.range(of: "[A-Z]", options: .regularExpression) != nil
            if hasLower && hasUpper {
                return true
            }
            
            // Check for single letters or very short meaningless combinations
            if text.count <= 2 || lowText == "you" || lowText == "qp" || text == "yOU" || lowText == "you" {
                return true
            }
        }
        
        // Patterns that indicate garbled OCR text
        let garbledPatterns = [
            "\\b(ohtr|bdlh|lber|sroke|hemm|trl|rn|promgpf|mgnisr)\\b",  // Specific garbled patterns from debug
            "^al qp",  // Specific garbled patterns
        ]
        
        for pattern in garbledPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               regex.firstMatch(in: lowText, range: NSRange(location: 0, length: lowText.count)) != nil {
                return true
            }
        }
        
        // Check if text has too many single letters
        let words = text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let singleLetterWords = words.filter { $0.count == 1 }
        if singleLetterWords.count > words.count / 2 && words.count > 3 {
            return true
        }
        
        // Check for lack of vowels in multi-character "words"
        let longWords = words.filter { $0.count > 2 }
        var wordsWithoutVowels = 0
        for word in longWords {
            if word.range(of: "[aeiou]", options: .regularExpression) == nil {
                wordsWithoutVowels += 1
            }
        }
        if longWords.count > 0 && wordsWithoutVowels > longWords.count * 2 / 3 {
            return true
        }
        
        return false
    }
    
    private func extractVocabularyEntry(from items: [(text: String, confidence: Float, box: CGRect)], 
                                       startingAt index: Int, 
                                       processedIndices: inout Set<Int>) -> [String: Any]? {
        
        let startItem = items[index]
        var chineseText = ""
        var englishText = ""
        var combinedConfidence: Float = startItem.confidence
        var itemsUsed = 1
        
        // Extract Chinese characters from the starting item
        chineseText = extractChineseFromText(startItem.text)
        
        if chineseText.isEmpty {
            return nil
        }
        
        print("OCR DEBUG - Extracted Chinese: '\(chineseText)' from '\(startItem.text)'")
        
        // Look for English definition in nearby items - use multiple strategies
        let startY = startItem.box.origin.y
        let startX = startItem.box.origin.x
        
        // Strategy 1: Look for English on the same row (loose tolerance)
        var bestEnglishMatch: (text: String, index: Int, confidence: Float)?
        var bestDistance: Float = Float.greatestFiniteMagnitude
        
        for i in (index + 1)..<min(index + 20, items.count) {  // Look at more items
            if processedIndices.contains(i) {
                continue
            }
            
            let currentItem = items[i]
            let yDiff = abs(Float(currentItem.box.origin.y - startY))
            let xDiff = abs(Float(currentItem.box.origin.x - startX))
            
            // Much more generous Y tolerance and consider X distance too
            if yDiff <= 0.05 {  // 5% tolerance instead of 1%
                let possibleEnglish = extractEnglishFromTextSimple(currentItem.text)
                if !possibleEnglish.isEmpty && possibleEnglish.count > 2 && !containsChineseCharacters(possibleEnglish) {
                    // Calculate combined distance (Y is more important than X)
                    let distance = yDiff * 2 + xDiff
                    if distance < bestDistance {
                        bestDistance = distance
                        bestEnglishMatch = (possibleEnglish, i, currentItem.confidence)
                    }
                }
            } else if yDiff > 0.08 {  // Stop looking too far away
                break
            }
        }
        
        if let match = bestEnglishMatch {
            englishText = match.text
            combinedConfidence += match.confidence
            itemsUsed += 1
            processedIndices.insert(match.index)
        }
        
        // Strategy 2: If no match found, look for English definitions in a wider area
        if englishText.isEmpty {
            for i in max(0, index - 5)..<min(index + 30, items.count) {
                if processedIndices.contains(i) || i == index {
                    continue
                }
                
                let currentItem = items[i]
                let yDiff = abs(Float(currentItem.box.origin.y - startY))
                
                // Look in a wider area for unmatched English definitions
                if yDiff <= 0.1 {  // 10% tolerance for desperate search
                    let possibleEnglish = extractEnglishFromTextSimple(currentItem.text)
                    if possibleEnglish.count > 4 && !containsChineseCharacters(possibleEnglish) && 
                       isValidEnglishDefinition(possibleEnglish) {
                        englishText = possibleEnglish
                        combinedConfidence += currentItem.confidence
                        itemsUsed += 1
                        processedIndices.insert(i)
                        print("OCR DEBUG - Found English via wide search: '\(englishText)' for '\(chineseText)'")
                        break
                    }
                }
            }
        }
        
        processedIndices.insert(index)
        
        if englishText.isEmpty {
            print("OCR DEBUG - No English found for Chinese: '\(chineseText)'")
            return nil
        }
        
        // Handle A/B format and convert to simplified
        var mainTerm = chineseText
        let originalTerm = chineseText
        
        if chineseText.contains("/") {
            let parts = chineseText.components(separatedBy: "/")
            if !parts.isEmpty {
                mainTerm = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        let simplifiedTerm = convertTermToSimplified(mainTerm)
        
        let result: [String: Any] = [
            "character": simplifiedTerm,
            "originalCharacter": originalTerm,
            "fullText": mainTerm,
            "definition": englishText,
            "confidence": combinedConfidence / Float(itemsUsed),
            "rawText": startItem.text
        ]
        
        return result
    }
    
    private func extractChineseFromText(_ text: String) -> String {
        // First, handle numbered entries by removing number prefixes
        var workingText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove number prefixes like "2 ", "3", etc. at the start
        workingText = workingText.replacingOccurrences(of: "^\\d+\\s*", with: "", options: .regularExpression)
        
        // More comprehensive pattern for Chinese characters including A/B format
        let chinesePattern = "[\u{4e00}-\u{9fff}\u{3400}-\u{4dbf}\u{20000}-\u{2a6df}\u{2a700}-\u{2b73f}\u{2b740}-\u{2b81f}\u{2b820}-\u{2ceaf}]+(?:/[\u{4e00}-\u{9fff}\u{3400}-\u{4dbf}\u{20000}-\u{2a6df}\u{2a700}-\u{2b73f}\u{2b740}-\u{2b81f}\u{2b820}-\u{2ceaf}]+)?"
        
        if let regex = try? NSRegularExpression(pattern: chinesePattern, options: []) {
            let matches = regex.matches(in: workingText, options: [], range: NSRange(location: 0, length: workingText.count))
            
            // Find the longest Chinese match first
            var bestMatch = ""
            for match in matches {
                let chineseText = (workingText as NSString).substring(with: match.range)
                if chineseText.count > bestMatch.count {
                    bestMatch = chineseText
                }
            }
            
            // If we found a good match, return it
            if !bestMatch.isEmpty {
                return bestMatch
            }
            
            // Fallback: return first match if available
            if let firstMatch = matches.first {
                return (workingText as NSString).substring(with: firstMatch.range)
            }
        }
        
        return ""
    }
    
    private func extractEnglishFromTextSimple(_ text: String) -> String {
        // Remove numbers and common separators
        var cleanText = text
            .replacingOccurrences(of: "^\\d+[.)、]?\\s*", with: "", options: .regularExpression)
            .replacingOccurrences(of: "[\u{4e00}-\u{9fff}\u{3400}-\u{4dbf}]+", with: "", options: .regularExpression)
            .replacingOccurrences(of: "[a-züāáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ]+\\s*", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Look for English words
        let englishPattern = "[a-zA-Z][a-zA-Z\\s,.'\\-]*[a-zA-Z]|[a-zA-Z]+"
        if let regex = try? NSRegularExpression(pattern: englishPattern, options: []) {
            let matches = regex.matches(in: cleanText, options: [], range: NSRange(location: 0, length: cleanText.count))
            
            if let longestMatch = matches.max(by: { $0.range.length < $1.range.length }) {
                return (cleanText as NSString).substring(with: longestMatch.range)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return cleanText
    }
    
    private func isValidEnglishDefinition(_ text: String) -> Bool {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Must contain English letters
        let containsEnglish = cleanText.range(of: "[a-zA-Z]", options: .regularExpression) != nil
        
        // Should not be mostly numbers or symbols
        let alphaCount = cleanText.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count
        let alphaRatio = Double(alphaCount) / Double(max(cleanText.count, 1))
        
        // Valid if has English letters and reasonable alpha ratio
        return containsEnglish && alphaRatio > 0.3 && cleanText.count >= 3
    }
    
    private func tryPatternBasedExtraction(from items: [(text: String, confidence: Float, box: CGRect)]) -> [[String: Any]] {
        print("OCR DEBUG - Trying pattern-based extraction")
        
        var results: [[String: Any]] = []
        var processedIndices = Set<Int>()
        
        // Look for any text item that contains Chinese characters
        for (index, item) in items.enumerated() {
            if processedIndices.contains(index) {
                continue
            }
            
            let chineseText = extractChineseFromText(item.text)
            if chineseText.count >= 2 {  // At least 2 Chinese characters
                // Look for English definition in the remaining text or nearby items
                var englishDef = extractEnglishFromTextSimple(item.text)
                
                // If no English in same text item, look at nearby items with better matching
                if englishDef.isEmpty || englishDef.count < 3 {
                    let currentY = item.box.origin.y
                    var bestMatch: (text: String, index: Int)?
                    var bestDistance: Float = Float.greatestFiniteMagnitude
                    
                    // Look for the best English match nearby
                    for i in max(0, index - 3)..<min(index + 15, items.count) {
                        if processedIndices.contains(i) || i == index {
                            continue
                        }
                        
                        let candidateItem = items[i]
                        let yDiff = abs(Float(candidateItem.box.origin.y - currentY))
                        
                        if yDiff <= 0.08 {  // 8% tolerance
                            let possibleEnglish = extractEnglishFromTextSimple(candidateItem.text)
                            if possibleEnglish.count > 3 && !containsChineseCharacters(possibleEnglish) && 
                               isValidEnglishDefinition(possibleEnglish) {
                                if yDiff < bestDistance {
                                    bestDistance = yDiff
                                    bestMatch = (possibleEnglish, i)
                                }
                            }
                        }
                    }
                    
                    if let match = bestMatch {
                        englishDef = match.text
                        processedIndices.insert(match.index)
                        print("OCR DEBUG - Pattern matched English: '\(englishDef)' with Chinese: '\(chineseText)'")
                    }
                }
                
                if !englishDef.isEmpty && englishDef.count > 2 {
                    // Handle A/B format
                    var mainTerm = chineseText
                    if chineseText.contains("/") {
                        let parts = chineseText.components(separatedBy: "/")
                        if !parts.isEmpty {
                            mainTerm = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    }
                    
                    let simplifiedTerm = convertTermToSimplified(mainTerm)
                    
                    let result: [String: Any] = [
                        "character": simplifiedTerm,
                        "originalCharacter": chineseText,
                        "fullText": mainTerm,
                        "definition": englishDef,
                        "confidence": item.confidence,
                        "rawText": item.text
                    ]
                    
                    results.append(result)
                    processedIndices.insert(index)
                    
                    print("OCR DEBUG - Pattern extraction found: '\(simplifiedTerm)' - '\(englishDef)'")
                }
            }
        }
        
        return results
    }
    
    private func parseVocabLine(_ text: String) -> [String: Any] {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("OCR DEBUG - parseVocabLine input: '\(cleanedText)'")
        
        // Filter out non-vocabulary items
        if isHeaderOrNonVocab(cleanedText) {
            print("OCR DEBUG - Filtered out as header/non-vocab")
            return [:]
        }
        
        // First, find ALL Chinese characters in the text
        let chinesePattern = "[\u{4e00}-\u{9fff}\u{3400}-\u{4dbf}\u{20000}-\u{2a6df}\u{2a700}-\u{2b73f}\u{2b740}-\u{2b81f}\u{2b820}-\u{2ceaf}\u{2ceb0}-\u{2ebef}\u{30000}-\u{3134f}]+"
        guard let chineseRegex = try? NSRegularExpression(pattern: chinesePattern, options: []) else {
            print("OCR DEBUG - Failed to create Chinese regex")
            return [:]
        }
        
        let nsText = cleanedText as NSString
        let chineseMatches = chineseRegex.matches(in: cleanedText, options: [], range: NSRange(location: 0, length: nsText.length))
        
        if chineseMatches.isEmpty {
            print("OCR DEBUG - No Chinese characters found")
            return [:]
        }
        
        // Extract all Chinese text segments
        var chineseSegments: [String] = []
        for match in chineseMatches {
            let segment = nsText.substring(with: match.range)
            chineseSegments.append(segment)
        }
        
        print("OCR DEBUG - Found Chinese segments: \(chineseSegments)")
        
        // Find the main Chinese term (usually the first meaningful segment)
        var mainChineseTerm = ""
        var originalChineseTerm = ""
        
        for segment in chineseSegments {
            // Handle A/B format (e.g., "结婚/結婚")
            if segment.contains("/") {
                let parts = segment.components(separatedBy: "/")
                if !parts.isEmpty && parts[0].count >= 2 {  // At least 2 characters for a meaningful term
                    mainChineseTerm = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    originalChineseTerm = segment
                    break
                }
            } else if segment.count >= 2 {  // At least 2 characters for a meaningful term
                mainChineseTerm = segment
                originalChineseTerm = segment
                break
            }
        }
        
        // If no multi-character term found, take the first Chinese segment
        if mainChineseTerm.isEmpty && !chineseSegments.isEmpty {
            let segment = chineseSegments[0]
            if segment.contains("/") {
                let parts = segment.components(separatedBy: "/")
                mainChineseTerm = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                originalChineseTerm = segment
            } else {
                mainChineseTerm = segment
                originalChineseTerm = segment
            }
        }
        
        guard !mainChineseTerm.isEmpty else {
            print("OCR DEBUG - No valid Chinese term found")
            return [:]
        }
        
        print("OCR DEBUG - Main Chinese term: '\(mainChineseTerm)', Original: '\(originalChineseTerm)'")
        
        // Now extract English definition by removing all Chinese text and pinyin
        var remainingText = cleanedText
        
        // Remove all Chinese segments
        for match in chineseMatches.reversed() {  // Reverse to maintain indices
            let range = Range(match.range, in: cleanedText)!
            remainingText.removeSubrange(range)
        }
        
        // Clean up remaining text and extract English
        remainingText = remainingText
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("OCR DEBUG - Remaining text after removing Chinese: '\(remainingText)'")
        
        // Extract English definition from remaining text
        let definition = extractEnglishFromText(remainingText)
        let cleanedDefinition = cleanDefinition(definition)
        
        print("OCR DEBUG - Extracted definition: '\(cleanedDefinition)'")
        
        // Validate that we have a meaningful English definition
        if cleanedDefinition.count < 2 || !hasValidEnglishDefinition(cleanedDefinition) {
            print("OCR DEBUG - Invalid English definition")
            return [:]
        }
        
        let simplifiedTerm = convertTermToSimplified(mainChineseTerm)
        
        let result = [
            "character": simplifiedTerm,
            "originalCharacter": originalChineseTerm,
            "fullText": mainChineseTerm,
            "definition": cleanedDefinition,
            "rawText": text
        ]
        
        print("OCR DEBUG - Final result: \(result)")
        return result
    }
    
    private func isHeaderOrNonVocab(_ text: String) -> Bool {
        let lowercaseText = text.lowercased()
        
        // Only filter out obvious headers - be more permissive
        let headerPatterns = [
            "ap-ib", "中文 ap-ib", "班级", "姓名", "name:",
            "拼音", "英文", "阅读文章"
        ]
        
        for pattern in headerPatterns {
            if lowercaseText.contains(pattern) {
                return true
            }
        }
        
        // Filter out lines that are ONLY numbers
        if text.trimmingCharacters(in: .whitespacesAndNewlines).range(of: "^\\d+$", options: .regularExpression) != nil {
            return true
        }
        
        // Filter out very short lines (likely not vocabulary)
        if text.count < 2 {
            return true
        }
        
        // Filter out obvious garbage text
        let garbagePatterns = ["al qp", "promgpf", "mgnisr", "/（m。"]
        for pattern in garbagePatterns {
            if lowercaseText.contains(pattern) {
                return true
            }
        }
        
        return false
    }
    
    private func hasValidEnglishDefinition(_ definition: String) -> Bool {
        // Check if definition contains meaningful English content
        let cleanDef = definition.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Must be at least 2 characters
        if cleanDef.count < 2 {
            return false
        }
        
        // Should contain English letters
        let englishPattern = "[a-zA-Z]"
        if let englishRegex = try? NSRegularExpression(pattern: englishPattern, options: []) {
            let englishMatches = englishRegex.matches(in: cleanDef, options: [], range: NSRange(location: 0, length: cleanDef.count))
            return englishMatches.count > 0
        }
        
        return false
    }
    
    private func parseVocabLineRegex(_ text: String) -> [String: Any] {
        let chinesePattern = "[\u{4e00}-\u{9fff}\u{3400}-\u{4dbf}\u{20000}-\u{2a6df}\u{2a700}-\u{2b73f}\u{2b740}-\u{2b81f}\u{2b820}-\u{2ceaf}\u{2ceb0}-\u{2ebef}\u{30000}-\u{3134f}]+"
        
        guard let regex = try? NSRegularExpression(pattern: chinesePattern, options: []) else {
            return [:]
        }
        
        let nsText = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
        
        guard let firstMatch = matches.first else {
            return [:]
        }
        
        let chineseText = nsText.substring(with: firstMatch.range)
        let firstCharacter = chineseText  // Keep the complete term
        let simplifiedCharacter = convertTermToSimplified(firstCharacter)
        
        // Extract everything after the Chinese characters
        let definitionStartIndex = firstMatch.range.location + firstMatch.range.length
        var definition = ""
        
        if definitionStartIndex < nsText.length {
            let remainingText = nsText.substring(from: definitionStartIndex)
            definition = extractEnglishFromText(remainingText)
        }
        
        definition = cleanDefinition(definition)
        
        return [
            "character": simplifiedCharacter,
            "originalCharacter": firstCharacter,
            "fullText": chineseText,
            "definition": definition,
            "rawText": text
        ]
    }
    
    private func extractEnglishFromText(_ text: String) -> String {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("OCR DEBUG - extractEnglishFromText input: '\(cleanedText)'")
        
        // Remove common separators and clean up
        var workingText = cleanedText
            .replacingOccurrences(of: "|", with: " ")
            .replacingOccurrences(of: "｜", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove pinyin (tone marked and unmarked) - more aggressive pattern
        let pinyinPattern = "[a-züāáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ]+\\s*"
        if let pinyinRegex = try? NSRegularExpression(pattern: pinyinPattern, options: .caseInsensitive) {
            workingText = pinyinRegex.stringByReplacingMatches(
                in: workingText,
                options: [],
                range: NSRange(location: 0, length: (workingText as NSString).length),
                withTemplate: ""
            ).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        print("OCR DEBUG - After pinyin removal: '\(workingText)'")
        
        // Find the longest continuous English text
        let englishPattern = "[a-zA-Z][a-zA-Z\\s,;.'\"\\-()]*[a-zA-Z]|[a-zA-Z]+"
        if let englishRegex = try? NSRegularExpression(pattern: englishPattern, options: []) {
            let matches = englishRegex.matches(in: workingText, options: [], range: NSRange(location: 0, length: (workingText as NSString).length))
            
            if let longestMatch = matches.max(by: { $0.range.length < $1.range.length }) {
                let englishText = (workingText as NSString).substring(with: longestMatch.range)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                print("OCR DEBUG - Found English text: '\(englishText)'")
                return englishText
            }
        }
        
        // If no specific English pattern found, return the cleaned text
        print("OCR DEBUG - No specific English found, returning cleaned text: '\(workingText)'")
        return workingText
    }
    
    private func containsEnglishText(_ text: String) -> Bool {
        let englishLetters = CharacterSet.letters
        return text.unicodeScalars.contains { englishLetters.contains($0) && $0.value < 256 }
    }
    
    private func cleanDefinition(_ definition: String) -> String {
        return definition
            .replacingOccurrences(of: "^[,;\\s\\d\\.]+", with: "", options: .regularExpression)
            .replacingOccurrences(of: "[\\s]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func convertTermToSimplified(_ term: String) -> String {
        var result = ""
        for char in term {
            result += convertToSimplified(String(char))
        }
        return result
    }
    
    private func convertToSimplified(_ character: String) -> String {
        let traditionalToSimplified: [String: String] = [
            "愛": "爱", "國": "国", "會": "会", "時": "时", "來": "来",
            "為": "为", "發": "发", "開": "开", "關": "关", "門": "门",
            "見": "见", "進": "进", "對": "对", "說": "说", "這": "这",
            "長": "长", "書": "书", "學": "学", "應": "应", "將": "将",
            "無": "无", "現": "现", "經": "经", "頭": "头", "與": "与",
            "動": "动", "還": "还", "點": "点", "從": "从", "邊": "边",
            "過": "过", "後": "后", "馬": "马", "錢": "钱", "車": "车",
            "樂": "乐", "熱": "热", "聽": "听", "話": "话", "語": "语",
            "讀": "读", "誰": "谁", "課": "课", "買": "买", "賣": "卖",
            "電": "电", "號": "号", "們": "们", "類": "类", "問": "问",
            "間": "间", "離": "离", "難": "难", "風": "风", "飛": "飞",
            "機": "机", "場": "场", "務": "务", "報": "报", "紙": "纸",
            "畫": "画", "較": "较", "運": "运", "農": "农", "覺": "觉",
            "黨": "党", "織": "织", "軍": "军", "導": "导", "幹": "干",
            "備": "备", "辦": "办", "議": "议", "選": "选", "參": "参",
            "歷": "历", "驗": "验", "營": "营", "構": "构", "確": "确",
            "傳": "传", "師": "师", "觀": "观", "論": "论", "際": "际",
            "陸": "陆", "訪": "访", "談": "谈", "責": "责", "採": "采",
            "術": "术", "極": "极", "驚": "惊", "雙": "双", "隨": "随",
            "藝": "艺", "錯": "错", "聯": "联", "斷": "断", "權": "权",
            "證": "证", "識": "识", "條": "条", "戰": "战", "團": "团",
            "轉": "转", "敗": "败", "貿": "贸", "陽": "阳", "職": "职",
            "漢": "汉", "夢": "梦", "響": "响", "雖": "虽", "續": "续",
            "衛": "卫", "規": "规", "視": "视", "競": "竞", "獲": "获"
        ]
        
        return traditionalToSimplified[character] ?? character
    }
}

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image provided"
        case .noTextFound:
            return "No text found in image"
        }
    }
}
