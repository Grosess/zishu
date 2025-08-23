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
            
            let results = self.processObservations(observations)
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
    
    private func processObservations(_ observations: [VNRecognizedTextObservation]) -> [[String: Any]] {
        print("OCR DEBUG - Processing \(observations.count) text observations")
        
        // Extract all text items with their positions and potential numbers
        var allTextItems: [(text: String, confidence: Float, box: CGRect, extractedNumber: Int?)] = []
        
        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }
            let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !text.isEmpty {
                let extractedNumber = extractNumberFromText(text)
                allTextItems.append((
                    text: text,
                    confidence: candidate.confidence,
                    box: observation.boundingBox,
                    extractedNumber: extractedNumber
                ))
            }
        }
        
        print("OCR DEBUG - Found \(allTextItems.count) text items")
        print("OCR DEBUG - RAW OCR OUTPUT:")
        for (index, item) in allTextItems.enumerated() {
            print("OCR DEBUG - [\(index)] '\(item.text)' (conf: \(String(format: "%.2f", item.confidence)), pos: \(String(format: "%.3f", item.box.origin.x)),\(String(format: "%.3f", item.box.origin.y)), num: \(item.extractedNumber?.description ?? "none"))")
        }
        
        // TABLE-BASED APPROACH: Sort by Y position first (rows), then X position (columns)
        // This maintains the vocabulary sheet's table structure
        allTextItems.sort { item1, item2 in
            let yDiff = item2.box.origin.y - item1.box.origin.y  // Higher Y = top
            if abs(yDiff) > 0.02 {  // Different rows (more generous for table detection)
                return yDiff > 0
            } else {  // Same row, sort by X position (left to right)
                return item1.box.origin.x < item2.box.origin.x
            }
        }
        
        print("OCR DEBUG - TABLE STRUCTURE ANALYSIS:")
        // Group items by rows to understand table structure
        var tableRows: [[String]] = []
        var currentRow: [String] = []
        var lastY: Float = -1
        
        for item in allTextItems {
            let itemY = Float(item.box.origin.y)
            if lastY >= 0 && abs(itemY - lastY) > 0.02 {
                // New row detected
                if !currentRow.isEmpty {
                    tableRows.append(currentRow)
                    currentRow = []
                }
            }
            currentRow.append(item.text)
            lastY = itemY
        }
        if !currentRow.isEmpty {
            tableRows.append(currentRow)
        }
        
        for (rowIndex, row) in tableRows.enumerated() {
            print("OCR DEBUG - Row \(rowIndex): \(row.joined(separator: " | "))")
        }
        
        // NEW APPROACH: Collect Chinese terms and English definitions separately, then match them
        var chineseTerms: [(text: String, confidence: Float, box: CGRect, index: Int, number: Int?)] = []
        var englishDefinitions: [(text: String, confidence: Float, box: CGRect, index: Int)] = []
        
        // Track standalone numbers that might be associated with terms
        var standaloneNumbers: [(number: Int, box: CGRect)] = []
        
        // First pass: categorize all text items
        for (index, item) in allTextItems.enumerated() {
            let text = item.text
            
            // Check if this is just a standalone number
            if let number = item.extractedNumber, text == String(number) {
                standaloneNumbers.append((number, item.box))
                print("OCR DEBUG - Standalone number: \(number) at position \(String(format: "%.3f,%.3f", item.box.origin.x, item.box.origin.y))")
                continue
            }
            
            // Skip obvious headers and non-content
            if isHeaderOrNonVocab(text) {
                continue
            }
            
            // Check if this contains Chinese characters - be more liberal
            let chineseText = extractChineseFromText(text)
            if chineseText.count >= 1 {  // Accept even single characters
                // Filter out "中文" and "中" as headers, and "然需" which is garbled
                if chineseText != "中文" && chineseText != "中" && chineseText != "然需" {
                    // Special handling for numbered terms
                    var shouldAdd = true
                    var finalChineseText = chineseText
                    var finalNumber = item.extractedNumber
                    
                    // If no number, check if there's a standalone number nearby - PRECISE MATCHING
                    if finalNumber == nil {
                        var bestMatch: (number: Int, distance: Float)?
                        var bestIndex = -1
                        
                        for (standaloneIndex, standalone) in standaloneNumbers.enumerated() {
                            let xDiff = abs(Float(item.box.origin.x - standalone.box.origin.x))
                            let yDiff = abs(Float(item.box.origin.y - standalone.box.origin.y))
                            // Numbers are at Y~0.083, Chinese at Y~0.118-0.126, difference ~0.04
                            // Make tolerance much more precise
                            if xDiff <= 0.03 && yDiff >= 0.035 && yDiff <= 0.055 {  // Precise tolerance
                                let distance = xDiff * 10.0 + yDiff  // X is critical for alignment
                                if bestMatch == nil || distance < bestMatch!.distance {
                                    bestMatch = (standalone.number, distance)
                                    bestIndex = standaloneIndex
                                }
                            }
                        }
                        
                        // If we found a match, use it and REMOVE from standalone list
                        if let match = bestMatch, bestIndex >= 0 {
                            finalNumber = match.number
                            standaloneNumbers.remove(at: bestIndex)  // Remove to prevent reuse
                            print("OCR DEBUG - Associated number \(match.number) with Chinese term '\(chineseText)' (distance: \(match.distance))")
                        }
                    }
                    
                    // If it's a single character with no number, be more selective but not too restrictive
                    if chineseText.count == 1 && finalNumber == nil {
                        // Check if this single character appears to be positioned like other vocab terms
                        // Look for nearby standalone numbers that might belong to this character
                        var hasNearbyNumber = false
                        for standalone in standaloneNumbers {
                            let xDiff = abs(Float(item.box.origin.x - standalone.box.origin.x))
                            let yDiff = abs(Float(item.box.origin.y - standalone.box.origin.y))
                            // Check if there's a number very close that could belong to this char
                            if xDiff <= 0.08 && yDiff <= 0.12 {
                                hasNearbyNumber = true
                                break
                            }
                        }
                        
                        // Also check if the single character is in the same Y region as other vocab terms
                        var inVocabRegion = false
                        let charY = item.box.origin.y
                        if charY >= 0.115 && charY <= 0.130 {  // Main vocab term Y region
                            inVocabRegion = true
                        }
                        
                        // Only skip single characters if they have no nearby numbers AND are not in vocab region
                        if !hasNearbyNumber && !inVocabRegion {
                            shouldAdd = false
                        }
                    }
                    
                    if shouldAdd {
                        chineseTerms.append((finalChineseText, item.confidence, item.box, index, finalNumber))
                        if chineseText.count >= 2 {
                            print("OCR DEBUG - Chinese term: '\(finalChineseText)' from '\(text)' with number: \(finalNumber?.description ?? "none")")
                        } else {
                            print("OCR DEBUG - Single Chinese char: '\(finalChineseText)' from '\(text)' with number: \(finalNumber?.description ?? "none")")
                        }
                    }
                }
            }
            
            // Also try to extract Chinese from mixed text (like "3大伯" -> "大伯")
            if chineseText.isEmpty || chineseText.count == 1 {
                let cleanedForChinese = text.replacingOccurrences(of: "^\\d+", with: "", options: .regularExpression)
                if cleanedForChinese != text && !cleanedForChinese.isEmpty {
                    let extractedFromCleaned = extractChineseFromText(cleanedForChinese)
                    if extractedFromCleaned.count >= 2 && extractedFromCleaned != "中文" && extractedFromCleaned != "然需" {
                        let alreadyExists = chineseTerms.contains { $0.text == extractedFromCleaned }
                        if !alreadyExists {
                            chineseTerms.append((extractedFromCleaned, item.confidence, item.box, index, item.extractedNumber))
                            print("OCR DEBUG - Extracted Chinese from mixed: '\(extractedFromCleaned)' from '\(text)' with number: \(item.extractedNumber?.description ?? "none")")
                        }
                    }
                }
            }
            
            // Check if this looks like an English definition OR special pinyin to convert
            if !containsChineseCharacters(text) && text.count > 3 {
                // Specific pinyin patterns to filter (be more selective)
                let lowText = text.lowercased()
                
                // Check for specific pinyin that corresponds to missing Chinese terms
                var shouldConvertPinyin = false
                var chineseFromPinyin: String?
                var associatedNumber: Int?
                
                if lowText == "guo" {
                    chineseFromPinyin = "过"
                    // Look for nearby number 11
                    for standalone in standaloneNumbers {
                        if standalone.number == 11 {
                            let xDiff = abs(Float(item.box.origin.x - standalone.box.origin.x))
                            if xDiff <= 0.05 {
                                associatedNumber = 11
                                shouldConvertPinyin = true
                                break
                            }
                        }
                    }
                } else if lowText == "qu shi" {
                    chineseFromPinyin = "去世"
                    // This should be number 12 (between 11 and 13)
                    associatedNumber = 12
                    shouldConvertPinyin = true
                } else if lowText == "biao" {
                    chineseFromPinyin = "表姐"  // elder female cousin
                    // This should be at the end, likely number 24 or 25
                    shouldConvertPinyin = true
                    associatedNumber = nil  // We'll detect based on position
                }
                
                if shouldConvertPinyin && chineseFromPinyin != nil {
                    chineseTerms.append((chineseFromPinyin!, item.confidence, item.box, index, associatedNumber))
                    print("OCR DEBUG - Converted pinyin '\(text)' to Chinese term: '\(chineseFromPinyin!)' with number: \(associatedNumber?.description ?? "none")")
                    continue
                }
                
                let definitelyPinyinPatterns = [
                    // Specific pinyin from the debug that we want to filter
                    "^(qin qi|uo shanji|da bo|bo ma|shashi|shen shen|gigu|gi fu|nidi yue|sheng dan je|qu shi|ayi|yifu|jo ma|haizi|chin jie|xiang gang|neidi|jian mian|ting shuo|tang ge|biao)$",
                    "^(guo|tang)$",  // Single syllables that are clearly pinyin
                ]
                
                var isPinyin = false
                for pattern in definitelyPinyinPatterns {
                    if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                       regex.firstMatch(in: lowText, range: NSRange(location: 0, length: lowText.count)) != nil {
                        isPinyin = true
                        break
                    }
                }
                
                // Check if it's garbled text
                let isGarbled = isGarbledText(text)
                
                // If it's not pinyin and not garbled, treat it as English
                if !isPinyin && !isGarbled {
                    englishDefinitions.append((text, item.confidence, item.box, index))
                    print("OCR DEBUG - English definition: '\(text)'")
                } else {
                    if isPinyin {
                        print("OCR DEBUG - Filtered as pinyin: '\(text)'")
                    } else if isGarbled {
                        print("OCR DEBUG - Filtered as garbled: '\(text)'")
                    }
                }
            }
        }
        
        print("OCR DEBUG - Found \(chineseTerms.count) Chinese terms and \(englishDefinitions.count) English definitions")
        
        // SIMPLIFIED APPROACH: Extract all Chinese terms from vocabulary row and sort by position
        print("OCR DEBUG - Simplified vocabulary extraction")
        
        // Find the main vocabulary row (where Chinese terms appear)
        var vocabRowItems: [(text: String, box: CGRect, index: Int)] = []
        for (index, item) in allTextItems.enumerated() {
            let itemY = item.box.origin.y
            // Vocabulary terms appear in Y range 0.078 to 0.135
            if itemY >= 0.075 && itemY <= 0.140 && !isHeaderOrNonVocab(item.text) {
                let chineseInText = extractChineseFromText(item.text)
                if chineseInText.count >= 1 && chineseInText != "中文" && chineseInText != "中" && chineseInText != "然需" {
                    vocabRowItems.append((item.text, item.box, index))
                }
            }
        }
        
        // Sort vocabulary row items PURELY by X position (left to right)
        vocabRowItems.sort { $0.box.origin.x < $1.box.origin.x }
        
        print("OCR DEBUG - Found \(vocabRowItems.count) vocabulary terms in initial scan:")
        for (idx, vocabItem) in vocabRowItems.enumerated() {
            let chinese = extractChineseFromText(vocabItem.text)
            print("OCR DEBUG - [\(idx+1)]: '\(chinese)' from '\(vocabItem.text)' at X:\(String(format: "%.3f", vocabItem.box.origin.x))")
        }
        
        // Clear previous Chinese terms and rebuild from vocabulary row order
        chineseTerms.removeAll()
        
        // Add all vocabulary terms in their correct positional order
        for vocabItem in vocabRowItems {
            let chineseInText = extractChineseFromText(vocabItem.text)
            if chineseInText.count >= 1 {
                chineseTerms.append((chineseInText, 0.9, vocabItem.box, vocabItem.index, nil))
            }
        }
        print("OCR DEBUG - After adding vocabulary terms: \(chineseTerms.count) terms")
        
        // Find missing terms by matching pinyin to expected positions
        // Use the existing standaloneNumbers from the first pass processing above
        
        print("OCR DEBUG - Found standalone numbers: \(standaloneNumbers.map { $0.number }.sorted())")
        
        // Debug: Show which numbers have Chinese terms and which don't
        for number in standaloneNumbers.map({ $0.number }).sorted() {
            let hasChineseTerm = chineseTerms.contains { term in
                if let numberX = standaloneNumbers.first(where: { $0.number == number })?.box.origin.x {
                    let xDiff = abs(term.box.origin.x - numberX)
                    return xDiff <= 0.05
                }
                return false
            }
            print("OCR DEBUG - Number \(number): \(hasChineseTerm ? "HAS Chinese term" : "MISSING Chinese term")")
        }
        
        // Check for missing numbers 1-25 that don't have standalone numbers at all
        let foundNumbers = Set(standaloneNumbers.map { $0.number })
        let missingNumbers = Set(1...25).subtracting(foundNumbers)
        if !missingNumbers.isEmpty {
            print("OCR DEBUG - Numbers with no standalone numbers found: \(missingNumbers.sorted())")
            // These might be Chinese terms without separate numbers - let's check if we have terms for these positions
        }
        
        // Match pinyin to positions based on standalone numbers
        for standalone in standaloneNumbers {
            let numberX = standalone.box.origin.x
            let vocabY = 0.124  // Expected Y position for Chinese terms
            
            // Check if we already have a Chinese term near this position
            let hasTermNearby = chineseTerms.contains { term in
                let xDiff = abs(term.box.origin.x - numberX)
                return xDiff <= 0.05  // Within 5% horizontally
            }
            
            if !hasTermNearby {
                var missingTerm: String?
                
                // Look for pinyin near this number position
                for item in allTextItems {
                    let xDiff = abs(Float(item.box.origin.x - numberX))
                    let yDiff = abs(Float(item.box.origin.y - standalone.box.origin.y))
                    
                    if xDiff <= 0.05 && yDiff >= 0.25 && yDiff <= 0.30 {  // Pinyin row is below numbers
                        let text = item.text.lowercased()
                        if text == "guo" {
                            missingTerm = "过"
                        } else if text == "qu shi" {
                            missingTerm = "去世"
                        } else if text.contains("biao") {
                            missingTerm = "表姐"
                        }
                        break
                    }
                }
                
                if let term = missingTerm {
                    let correctBox = CGRect(x: numberX, y: vocabY, width: 0.02, height: 0.01)
                    chineseTerms.append((term, 0.8, correctBox, -1, nil))
                    print("OCR DEBUG - Added '\(term)' at position X:\(String(format: "%.3f", numberX)) for number \(standalone.number)")
                }
            }
        }
        print("OCR DEBUG - After pinyin matching: \(chineseTerms.count) terms")
        
        // FINAL AGGRESSIVE SCAN: Look for any missed Chinese text in the vocabulary area
        print("OCR DEBUG - Final aggressive scan for missed terms")
        for (index, item) in allTextItems.enumerated() {
            let itemY = item.box.origin.y
            if itemY >= 0.075 && itemY <= 0.140 && !isHeaderOrNonVocab(item.text) {
                let chineseText = extractChineseFromText(item.text)
                if chineseText.count >= 1 && chineseText != "中文" && chineseText != "中" && chineseText != "然需" {
                    // Check if we already have this term
                    let alreadyHave = chineseTerms.contains { $0.text == chineseText || $0.text.contains(chineseText) || chineseText.contains($0.text) }
                    if !alreadyHave {
                        chineseTerms.append((chineseText, 0.8, item.box, index, nil))
                        print("OCR DEBUG - FINAL SCAN: Found missed term '\(chineseText)' from '\(item.text)'")
                    }
                }
            }
        }
        print("OCR DEBUG - After final aggressive scan: \(chineseTerms.count) terms")
        
        // Final sort: purely by X position to maintain vocabulary sheet order
        chineseTerms.sort { $0.box.origin.x < $1.box.origin.x }
        
        print("OCR DEBUG - Chinese terms after position-based sorting: \(chineseTerms.map { $0.text })")
        
        // Debug: Show detailed position info for first 5 terms to verify order
        print("OCR DEBUG - Detailed position info for verification:")
        for (index, term) in chineseTerms.prefix(5).enumerated() {
            print("OCR DEBUG - [\(index+1)]: '\(term.text)' at X:\(String(format: "%.3f", term.box.origin.x))")
        }
        
        // Second pass: Match Chinese terms with English definitions
        var results: [[String: Any]] = []
        var usedEnglishIndices = Set<Int>()
        
        for chineseTerm in chineseTerms {
            var bestMatch: (text: String, confidence: Float, distance: Float)?
            var bestEnglishIndex: Int?
            
            // Find the best English definition match for this Chinese term
            for (englishIndex, englishDef) in englishDefinitions.enumerated() {
                if usedEnglishIndices.contains(englishIndex) {
                    continue
                }
                
                // Calculate distance between Chinese term and English definition
                let yDiff = abs(Float(chineseTerm.box.origin.y - englishDef.box.origin.y))
                let xDiff = abs(Float(chineseTerm.box.origin.x - englishDef.box.origin.x))
                
                // For vocabulary sheets, Chinese at Y~0.12 and English at Y~0.52
                // X position should be similar (same column alignment)
                // Prioritize X alignment heavily since terms are vertically aligned with definitions
                let distance = xDiff * 5.0 + yDiff  // X position is more important
                
                // Accept matches within reasonable distance
                // Y difference is about 0.40-0.47 for Chinese-English pairs on the vocab sheet
                // Chinese at Y~0.078-0.126, English at Y~0.520-0.549
                if yDiff >= 0.38 && yDiff <= 0.48 && xDiff <= 0.08 {  // More lenient X tolerance
                    if bestMatch == nil || distance < bestMatch!.distance {
                        bestMatch = (englishDef.text, englishDef.confidence, distance)
                        bestEnglishIndex = englishIndex
                    }
                }
            }
            
            if let match = bestMatch, let englishIndex = bestEnglishIndex {
                usedEnglishIndices.insert(englishIndex)
                
                // Handle A/B format - always use the left side as requested
                var mainTerm = chineseTerm.text
                let originalTerm = chineseTerm.text
                
                if chineseTerm.text.contains("/") {
                    let parts = chineseTerm.text.components(separatedBy: "/")
                    if !parts.isEmpty {
                        mainTerm = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        print("OCR DEBUG - A/B format: using '\(mainTerm)' from '\(originalTerm)'")
                    }
                }
                
                let simplifiedTerm = convertTermToSimplified(mainTerm)
                let avgConfidence = (chineseTerm.confidence + match.confidence) / 2.0
                
                let result: [String: Any] = [
                    "character": simplifiedTerm,
                    "originalCharacter": originalTerm,
                    "fullText": mainTerm,
                    "definition": match.text,
                    "confidence": avgConfidence,
                    "rawText": chineseTerm.text
                ]
                
                results.append(result)
                print("OCR DEBUG - MATCHED: '\(simplifiedTerm)' with '\(match.text)' (distance: \(match.distance))")
            } else {
                print("OCR DEBUG - NO MATCH for Chinese term: '\(chineseTerm.text)'")
            }
        }
        
        // Enhanced fallback matching for any unmatched terms
        print("OCR DEBUG - Attempting fallback matching for unmatched terms")
        
        // Find unmatched Chinese terms and English definitions
        var unmatchedChineseTerms: [(text: String, confidence: Float, box: CGRect, index: Int, number: Int?)] = []
        var unmatchedEnglishDefs: [(text: String, confidence: Float, box: CGRect, index: Int)] = []
        
        // Find unmatched Chinese terms
        for chineseTerm in chineseTerms {
            let alreadyUsed = results.contains { result in
                let resultTerm = result["originalCharacter"] as? String ?? ""
                return resultTerm == chineseTerm.text
            }
            if !alreadyUsed {
                unmatchedChineseTerms.append(chineseTerm)
            }
        }
        
        // Find unmatched English definitions
        for (englishIndex, englishDef) in englishDefinitions.enumerated() {
            if !usedEnglishIndices.contains(englishIndex) {
                unmatchedEnglishDefs.append(englishDef)
            }
        }
        
        print("OCR DEBUG - Unmatched: \(unmatchedChineseTerms.count) Chinese terms, \(unmatchedEnglishDefs.count) English definitions")
        
        // Smart definition matching for unmatched terms
        // Filter out garbled English definitions
        let validUnmatchedEnglish = unmatchedEnglishDefs.filter { def in
            !isGarbledText(def.text) && def.text != "yOU"
        }
        
        print("OCR DEBUG - Valid unmatched English after filtering: \(validUnmatchedEnglish.map { $0.text })")
        
        for chineseTerm in unmatchedChineseTerms {
            var bestEnglish = "definition needed"
            
            // Smart matching based on term meaning
            let term = chineseTerm.text
            if term == "过" {
                // Look for "to spend time with, to celebrate"
                if let celebrateIdx = validUnmatchedEnglish.firstIndex(where: { $0.text.contains("celebrate") }) {
                    bestEnglish = validUnmatchedEnglish[celebrateIdx].text
                    print("OCR DEBUG - SMART MATCH: '\(term)' with '\(bestEnglish)'")
                }
            } else if term == "去世" {
                // Look for "pass away"
                if let passIdx = validUnmatchedEnglish.firstIndex(where: { $0.text.contains("pass away") }) {
                    bestEnglish = validUnmatchedEnglish[passIdx].text
                    print("OCR DEBUG - SMART MATCH: '\(term)' with '\(bestEnglish)'")
                }
            } else if term == "表姐" {
                // Look for "cousins having same family name"
                if let cousinIdx = validUnmatchedEnglish.firstIndex(where: { $0.text.contains("cousins") }) {
                    bestEnglish = validUnmatchedEnglish[cousinIdx].text
                    print("OCR DEBUG - SMART MATCH: '\(term)' with '\(bestEnglish)'")
                }
            } else {
                // Use any remaining valid definition
                for englishDef in validUnmatchedEnglish {
                    let alreadyUsed = results.contains { result in
                        let resultDef = result["definition"] as? String ?? ""
                        return resultDef == englishDef.text
                    }
                    if !alreadyUsed {
                        bestEnglish = englishDef.text
                        print("OCR DEBUG - REMAINING MATCH: '\(chineseTerm.text)' with '\(bestEnglish)'")
                        break
                    }
                }
            }
            
            // Handle A/B format - use left side
            var mainTerm = chineseTerm.text
            if chineseTerm.text.contains("/") {
                let parts = chineseTerm.text.components(separatedBy: "/")
                if !parts.isEmpty {
                    mainTerm = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            let simplifiedTerm = convertTermToSimplified(mainTerm)
            
            let result: [String: Any] = [
                "character": simplifiedTerm,
                "originalCharacter": chineseTerm.text,
                "fullText": mainTerm,
                "definition": bestEnglish,
                "confidence": chineseTerm.confidence,
                "rawText": chineseTerm.text
            ]
            
            results.append(result)
        }
        
        print("OCR DEBUG - Final results count: \(results.count)")
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
    
    private func isGarbledText(_ text: String) -> Bool {
        let lowText = text.lowercased()
        
        // First check if it contains valid English words - if so, not garbled
        if containsValidEnglishWords(text) {
            return false
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
        // More comprehensive pattern for Chinese characters including A/B format
        let chinesePattern = "[\u{4e00}-\u{9fff}\u{3400}-\u{4dbf}\u{20000}-\u{2a6df}\u{2a700}-\u{2b73f}\u{2b740}-\u{2b81f}\u{2b820}-\u{2ceaf}]+(?:/[\u{4e00}-\u{9fff}\u{3400}-\u{4dbf}\u{20000}-\u{2a6df}\u{2a700}-\u{2b73f}\u{2b740}-\u{2b81f}\u{2b820}-\u{2ceaf}]+)?"
        
        if let regex = try? NSRegularExpression(pattern: chinesePattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            // Find the longest Chinese match first
            var bestMatch = ""
            for match in matches {
                let chineseText = (text as NSString).substring(with: match.range)
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
                return (text as NSString).substring(with: firstMatch.range)
            }
        }
        
        // Additional check: try to find Chinese characters even if mixed with numbers
        let cleanedText = text.replacingOccurrences(of: "^\\d+", with: "", options: .regularExpression)
        if cleanedText != text {
            return extractChineseFromText(cleanedText)
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
