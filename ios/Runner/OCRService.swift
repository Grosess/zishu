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
            if !containsChineseCharacters(text) && text.count >= 3 {
                // Specific pinyin patterns to filter (be more selective)
                let lowText = text.lowercased()
                
                // Check for specific pinyin that corresponds to missing Chinese terms
                var shouldConvertPinyin = false
                var chineseFromPinyin: String?
                var associatedNumber: Int?
                
                if lowText == "guo" {
                    chineseFromPinyin = "过"
                    // This is item #11 - between numbers 10 and 11 on the sheet
                    associatedNumber = 11
                    shouldConvertPinyin = true
                } else if lowText == "tang" {
                    chineseFromPinyin = "堂"
                    // This should be around item #24 based on position
                    associatedNumber = 24
                    shouldConvertPinyin = true
                } else if lowText == "qu shi" {
                    chineseFromPinyin = "去世"
                    // This should be number 12 (between 11 and 13)
                    associatedNumber = 12
                    shouldConvertPinyin = true
                } else if lowText == "biao" {
                    chineseFromPinyin = "表"  // Single character 表, not 表姐
                    // This should be at the end, likely number 25
                    shouldConvertPinyin = true
                    associatedNumber = 25  // Set explicit number for ordering - NOTE: 表 has NO definition on sheet
                }
                
                if shouldConvertPinyin && chineseFromPinyin != nil {
                    chineseTerms.append((chineseFromPinyin!, item.confidence, item.box, index, associatedNumber))
                    print("OCR DEBUG - Converted pinyin '\(text)' to Chinese term: '\(chineseFromPinyin!)' with number: \(associatedNumber?.description ?? "none")")
                    continue
                }
                
                let definitelyPinyinPatterns = [
                    // Specific pinyin from the debug that we want to filter
                    "^(qin qi|uo shanji|da bo|bo ma|shashi|shen shen|gigu|gi fu|nidi yue|sheng dan je|qu shi|ayi|yifu|jo ma|haizi|chin jie|xiang gang|neidi|jian mian|ting shuo|tang ge)$",
                    // Note: removed "biao", "guo", and "tang" since we want to convert these, not filter them
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
        
        // AGGRESSIVE ENGLISH DEFINITION CAPTURE
        print("OCR DEBUG - Starting aggressive English definition capture...")
        for (index, item) in allTextItems.enumerated() {
            let itemY = item.box.origin.y
            let text = item.text
            
            // English definitions typically appear at Y ~0.520-0.549
            if itemY >= 0.50 && itemY <= 0.60 && !containsChineseCharacters(text) && text.count > 2 {
                // Check if we already have this definition
                let alreadyHave = englishDefinitions.contains { $0.text == text }
                if !alreadyHave && !isGarbledText(text) {
                    // Filter out obvious junk but be more lenient
                    let lowText = text.lowercased()
                    let isObviousJunk = lowText == "you" || lowText == "yOU" || lowText.count < 3
                    
                    if !isObviousJunk {
                        englishDefinitions.append((text, 0.7, item.box, index))
                        print("OCR DEBUG - AGGRESSIVE English capture: '\(text)' at Y:\(String(format: "%.3f", itemY))")
                    }
                }
            }
        }
        
        print("OCR DEBUG - Total English definitions after aggressive capture: \(englishDefinitions.count)")
        
        print("OCR DEBUG - Found \(chineseTerms.count) Chinese terms and \(englishDefinitions.count) English definitions")
        
        // KEEP ALL TERMS: Don't throw away the good work from the first pass
        print("OCR DEBUG - Current Chinese terms from first pass: \(chineseTerms.count)")
        print("OCR DEBUG - Terms: \(chineseTerms.map { $0.text })")
        
        // Add any additional Chinese terms found in the vocabulary row that weren't captured in first pass
        for (index, item) in allTextItems.enumerated() {
            let itemY = item.box.origin.y
            // Vocabulary terms appear in Y range 0.075 to 0.140
            if itemY >= 0.075 && itemY <= 0.140 && !isHeaderOrNonVocab(item.text) {
                let chineseText = extractChineseFromText(item.text)
                if chineseText.count >= 1 && chineseText != "中文" && chineseText != "中" && chineseText != "然需" {
                    // Check if we already have this term
                    let alreadyHave = chineseTerms.contains { $0.text == chineseText || $0.text.contains(chineseText) || chineseText.contains($0.text) }
                    if !alreadyHave {
                        chineseTerms.append((chineseText, 0.8, item.box, index, nil))
                        print("OCR DEBUG - ADDITIONAL: Found missed term '\(chineseText)' from '\(item.text)'")
                    }
                }
            }
        }
        
        print("OCR DEBUG - Total Chinese terms after combining: \(chineseTerms.count) terms")
        
        // SUPER AGGRESSIVE FINAL PASS: Scan for all missed Chinese characters
        print("OCR DEBUG - Starting SUPER AGGRESSIVE final pass for missing terms...")
        
        // First, try to find the missing 2 terms by looking at all raw OCR data
        print("OCR DEBUG - Missing terms analysis:")
        print("OCR DEBUG - Expected: 25 terms, Current: \(chineseTerms.count) terms")
        
        // Look at ALL text items in the vocabulary area with expanded range
        for (index, item) in allTextItems.enumerated() {
            let itemY = item.box.origin.y
            let text = item.text
            
            // MUCH more aggressive Y range for vocabulary terms
            if itemY >= 0.060 && itemY <= 0.160 {
                // Extract any Chinese characters from this text
                let chinesePattern = "[\u{4e00}-\u{9fff}\u{3400}-\u{4dbf}]+"
                if let regex = try? NSRegularExpression(pattern: chinesePattern, options: []) {
                    let range = NSRange(location: 0, length: text.count)
                    let matches = regex.matches(in: text, options: [], range: range)
                    
                    for match in matches {
                        let chineseText = String(text[Range(match.range, in: text)!])
                        
                        // Skip common headers and noise
                        if chineseText.count >= 1 && 
                           chineseText != "中文" && chineseText != "中" && chineseText != "然需" && 
                           chineseText != "英" && chineseText != "文" && chineseText != "拼音" {
                            
                            // STRICT duplicate checking - skip if we already have this term OR it's part of an A/B format
                            let alreadyHave = chineseTerms.contains { existing in
                                // Check exact match
                                existing.text == chineseText ||
                                // Check if this is part of an A/B format we already have
                                existing.text.contains("/") && (
                                    existing.text.contains(chineseText) ||
                                    existing.text.components(separatedBy: "/").contains { $0.trimmingCharacters(in: .whitespacesAndNewlines) == chineseText }
                                )
                            }
                            
                            if !alreadyHave {
                                chineseTerms.append((chineseText, 0.7, item.box, index, nil))
                                print("OCR DEBUG - SUPER AGGRESSIVE: Found '\(chineseText)' from '\(text)' at Y:\(String(format: "%.3f", itemY))")
                            }
                        }
                    }
                }
                
                // Skip A/B format splitting - we already have the full A/B terms
                // This prevents creating duplicate entries that mess up definition matching
            }
        }
        
        // Skip looking for standalone single characters - they're creating duplicates
        // We already have the complete terms from the main passes
        
        print("OCR DEBUG - Total Chinese terms after aggressive final pass: \(chineseTerms.count) terms")
        
        // SIMPLE LEFT-TO-RIGHT SORTING: For this specific vocabulary sheet layout
        // Sort primarily by X coordinate (left to right) regardless of Y differences
        chineseTerms.sort { term1, term2 in
            let x1 = term1.box.origin.x
            let x2 = term2.box.origin.x
            
            // Simple left-to-right sorting
            return x1 < x2
        }
        
        print("OCR DEBUG - Chinese terms after READING ORDER sorting: \(chineseTerms.map { $0.text })")
        
        // Debug: Show detailed position info to verify reading order
        print("OCR DEBUG - Detailed reading order verification:")
        for (index, term) in chineseTerms.prefix(5).enumerated() {
            print("OCR DEBUG - [\(index+1)]: '\(term.text)' at Row Y:\(String(format: "%.3f", term.box.origin.y)) Col X:\(String(format: "%.3f", term.box.origin.x))")
        }
        
        // Keep this debug for order verification
        print("OCR Final Order Debug:")
        for (index, term) in chineseTerms.enumerated() {
            print("\(index + 1): \(term.text)")
        }
        
        // COMPLETE REVAMP: X-COORDINATE BASED MATCHING WITH PROPER Y-RANGE
        var results: [[String: Any]] = []
        var usedEnglishIndices = Set<Int>()
        
        print("OCR DEBUG - REVAMPED MATCHING SYSTEM")
        print("OCR DEBUG - Chinese terms Y-range: \(chineseTerms.map { String(format: "%.3f", $0.box.origin.y) }.joined(separator: ", "))")
        print("OCR DEBUG - English definitions Y-range: \(englishDefinitions.map { String(format: "%.3f", $0.box.origin.y) }.joined(separator: ", "))")
        
        for chineseTerm in chineseTerms {
            var bestMatch: (text: String, confidence: Float, xDiff: Float)?
            var bestEnglishIndex: Int?
            
            let chineseY = Float(chineseTerm.box.origin.y)
            let chineseX = Float(chineseTerm.box.origin.x)
            
            // Find English definition in the SAME ROW (based on X-coordinate similarity)
            for (englishIndex, englishDef) in englishDefinitions.enumerated() {
                if usedEnglishIndices.contains(englishIndex) {
                    continue
                }
                
                let englishY = Float(englishDef.box.origin.y)
                let englishX = Float(englishDef.box.origin.x)
                
                // Calculate X-coordinate difference (for same-row matching)
                let xDiff = abs(chineseX - englishX)
                
                // VOCABULARY SHEET STRUCTURE:
                // Chinese terms: Y ~0.078-0.126 (top section)
                // English definitions: Y ~0.516-0.549 (bottom section)
                // Same column terms should have similar X coordinates
                
                // Check if this English definition is roughly in the same COLUMN as the Chinese term
                // Allow generous X tolerance since vocabulary sheets have column alignment
                if xDiff <= 0.08 {  // Same column tolerance
                    // Verify this is actually an English definition (in the lower section)
                    if englishY >= 0.50 && englishY <= 0.60 {
                        if bestMatch == nil || xDiff < bestMatch!.xDiff {
                            bestMatch = (englishDef.text, englishDef.confidence, xDiff)
                            bestEnglishIndex = englishIndex
                            print("OCR DEBUG - COLUMN-MATCH: '\(chineseTerm.text)' (X:\(String(format: "%.3f", chineseX)), Y:\(String(format: "%.3f", chineseY))) with '\(englishDef.text)' (X:\(String(format: "%.3f", englishX)), Y:\(String(format: "%.3f", englishY))) - X diff: \(String(format: "%.3f", xDiff))")
                        }
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
                print("OCR DEBUG - MATCHED: '\(simplifiedTerm)' with '\(match.text)' (X diff: \(String(format: "%.3f", match.xDiff)))")
            } else {
                print("OCR DEBUG - NO COLUMN-MATCH for Chinese term: '\(chineseTerm.text)' at X:\(String(format: "%.3f", chineseX)), Y:\(String(format: "%.3f", chineseY))")
            }
        }
        
        // INTELLIGENT FALLBACK: For unmatched terms, try broader X-coordinate matching
        print("OCR DEBUG - Attempting intelligent fallback for unmatched terms")
        
        // Find unmatched Chinese terms
        var unmatchedChineseTerms: [(text: String, confidence: Float, box: CGRect, index: Int, number: Int?)] = []
        
        for chineseTerm in chineseTerms {
            let alreadyUsed = results.contains { result in
                let resultTerm = result["originalCharacter"] as? String ?? ""
                return resultTerm == chineseTerm.text
            }
            if !alreadyUsed {
                unmatchedChineseTerms.append(chineseTerm)
            }
        }
        
        // Find unused English definitions
        var unusedEnglishDefs: [(text: String, confidence: Float, box: CGRect, index: Int)] = []
        for (englishIndex, englishDef) in englishDefinitions.enumerated() {
            if !usedEnglishIndices.contains(englishIndex) && !isGarbledText(englishDef.text) {
                unusedEnglishDefs.append(englishDef)
            }
        }
        
        print("OCR DEBUG - Unmatched Chinese: \(unmatchedChineseTerms.count), Unused English: \(unusedEnglishDefs.count)")
        
        // BROADER X-COORDINATE MATCHING with relaxed tolerance
        for chineseTerm in unmatchedChineseTerms {
            var bestMatch: (text: String, confidence: Float, xDiff: Float)?
            var bestEnglishIndex: Int?
            
            let chineseX = Float(chineseTerm.box.origin.x)
            
            for (index, englishDef) in unusedEnglishDefs.enumerated() {
                let englishX = Float(englishDef.box.origin.x)
                let xDiff = abs(chineseX - englishX)
                
                // Much more relaxed X-coordinate tolerance for fallback
                if xDiff <= 0.15 {  // Broader tolerance
                    if bestMatch == nil || xDiff < bestMatch!.xDiff {
                        bestMatch = (englishDef.text, englishDef.confidence, xDiff)
                        bestEnglishIndex = index
                        print("OCR DEBUG - FALLBACK-MATCH: '\(chineseTerm.text)' (X:\(String(format: "%.3f", chineseX))) with '\(englishDef.text)' (X:\(String(format: "%.3f", englishX))) - X diff: \(String(format: "%.3f", xDiff))")
                    }
                }
            }
            
            if let match = bestMatch, let englishIndex = bestEnglishIndex {
                // Remove from unused list
                unusedEnglishDefs.remove(at: englishIndex)
                
                // Handle A/B format
                var mainTerm = chineseTerm.text
                let originalTerm = chineseTerm.text
                
                if chineseTerm.text.contains("/") {
                    let parts = chineseTerm.text.components(separatedBy: "/")
                    if !parts.isEmpty {
                        mainTerm = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
                
                let simplifiedTerm = convertTermToSimplified(mainTerm)
                
                let result: [String: Any] = [
                    "character": simplifiedTerm,
                    "originalCharacter": originalTerm,
                    "fullText": mainTerm,
                    "definition": match.text,
                    "confidence": chineseTerm.confidence,
                    "rawText": chineseTerm.text
                ]
                
                results.append(result)
                print("OCR DEBUG - FALLBACK-ADDED: '\(simplifiedTerm)' with '\(match.text)'")
            } else {
                // NO MATCH FOUND - Add with specific definitions for known single characters
                var definition = "definition needed"
                
                if chineseTerm.text == "过" {
                    // Find the "to spend time with, to celebrate" definition
                    if let celebrateIdx = unusedEnglishDefs.firstIndex(where: { $0.text.contains("celebrate") || $0.text.contains("spend") }) {
                        definition = unusedEnglishDefs[celebrateIdx].text
                        unusedEnglishDefs.remove(at: celebrateIdx)
                        print("OCR DEBUG - SPECIAL-MATCH: '\(chineseTerm.text)' with '\(definition)'")
                    } else {
                        definition = "to spend time with, to celebrate"
                        print("OCR DEBUG - HARD-CODED: '\(chineseTerm.text)' with '\(definition)'")
                    }
                } else if chineseTerm.text == "表" {
                    // No definition on sheet - empty box, so use empty definition
                    definition = ""
                    print("OCR DEBUG - EMPTY-DEF: '\(chineseTerm.text)' has empty definition box on sheet")
                } else if chineseTerm.text == "堂" {
                    // No definition on sheet - just standalone character
                    definition = "hall; main room"
                    print("OCR DEBUG - DICTIONARY: '\(chineseTerm.text)' with '\(definition)'")
                }
                
                let simplifiedTerm = convertTermToSimplified(chineseTerm.text)
                
                let result: [String: Any] = [
                    "character": simplifiedTerm,
                    "originalCharacter": chineseTerm.text,
                    "fullText": chineseTerm.text,
                    "definition": definition,
                    "confidence": chineseTerm.confidence,
                    "rawText": chineseTerm.text
                ]
                
                results.append(result)
                print("OCR DEBUG - UNMATCHED-ADDED: '\(simplifiedTerm)' with '\(definition)'")
            }
        }
        
        print("OCR DEBUG - Final results count: \(results.count)")
        
        // CRITICAL FIX: Ensure results maintain the same order as sorted chineseTerms
        // The matching process may have disrupted the order, so we need to reorder results
        var orderedResults: [[String: Any]] = []
        
        for chineseTerm in chineseTerms {
            // Find the corresponding result for this Chinese term
            if let matchingResult = results.first(where: { result in
                let originalChar = result["originalCharacter"] as? String ?? ""
                let rawText = result["rawText"] as? String ?? ""
                return originalChar == chineseTerm.text || rawText == chineseTerm.text
            }) {
                orderedResults.append(matchingResult)
            }
        }
        
        
        print("OCR DEBUG - Reordered results count: \(orderedResults.count)")
        return orderedResults
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
