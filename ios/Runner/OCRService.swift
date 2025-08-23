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
        
        // Extract all text items with their positions
        var allTextItems: [(text: String, confidence: Float, box: CGRect)] = []
        
        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }
            let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !text.isEmpty {
                allTextItems.append((
                    text: text,
                    confidence: candidate.confidence,
                    box: observation.boundingBox
                ))
            }
        }
        
        print("OCR DEBUG - Found \(allTextItems.count) text items")
        
        // Sort by Y position (top to bottom), then by X position (left to right)
        allTextItems.sort { item1, item2 in
            let yDiff = item2.box.origin.y - item1.box.origin.y  // Higher Y = top
            if abs(yDiff) > 0.01 {  // Different rows
                return yDiff > 0
            } else {  // Same row, sort by X position
                return item1.box.origin.x < item2.box.origin.x
            }
        }
        
        // NEW APPROACH: Collect Chinese terms and English definitions separately, then match them
        var chineseTerms: [(text: String, confidence: Float, box: CGRect, index: Int)] = []
        var englishDefinitions: [(text: String, confidence: Float, box: CGRect, index: Int)] = []
        
        // First pass: categorize all text items
        for (index, item) in allTextItems.enumerated() {
            let text = item.text
            
            // Skip obvious headers and non-content
            if isHeaderOrNonVocab(text) {
                continue
            }
            
            // Check if this contains Chinese characters
            let chineseText = extractChineseFromText(text)
            if chineseText.count >= 2 {  // Meaningful Chinese term
                chineseTerms.append((chineseText, item.confidence, item.box, index))
                print("OCR DEBUG - Chinese term: '\(chineseText)' from '\(text)'")
            }
            
            // Check if this looks like an English definition - be much more permissive
            if !containsChineseCharacters(text) && text.count > 3 {
                // Skip obvious non-English patterns
                let lowText = text.lowercased()
                let skipPatterns = ["qin qi", "da bo", "bo ma", "shen shen", "ayi", "yifu", "haizi", "tang ge", "biao"]
                let shouldSkip = skipPatterns.contains { lowText.contains($0) }
                
                if !shouldSkip {
                    // Accept any text that looks like it could be English
                    let hasEnglish = text.range(of: "[a-zA-Z]", options: .regularExpression) != nil
                    if hasEnglish {
                        englishDefinitions.append((text, item.confidence, item.box, index))
                        print("OCR DEBUG - English definition: '\(text)'")
                    }
                }
            }
        }
        
        print("OCR DEBUG - Found \(chineseTerms.count) Chinese terms and \(englishDefinitions.count) English definitions")
        
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
                
                // Prioritize Y distance (same row), then X distance (reading order)
                let distance = yDiff * 3.0 + xDiff
                
                // Accept matches within reasonable distance
                if yDiff <= 0.15 {  // 15% Y tolerance - very generous
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
        
        // If we didn't match many terms, try to create entries even with imperfect matches
        if results.count < chineseTerms.count / 2 {
            print("OCR DEBUG - Few matches found, creating entries for remaining Chinese terms")
            
            for chineseTerm in chineseTerms {
                // Skip if already used
                let alreadyUsed = results.contains { result in
                    let resultTerm = result["originalCharacter"] as? String ?? ""
                    return resultTerm == chineseTerm.text
                }
                
                if !alreadyUsed {
                    // Handle A/B format - use left side
                    var mainTerm = chineseTerm.text
                    if chineseTerm.text.contains("/") {
                        let parts = chineseTerm.text.components(separatedBy: "/")
                        if !parts.isEmpty {
                            mainTerm = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    }
                    
                    let simplifiedTerm = convertTermToSimplified(mainTerm)
                    
                    // Try to find ANY English text that hasn't been used
                    var bestEnglish = "definition needed"  // Default
                    for (englishIndex, englishDef) in englishDefinitions.enumerated() {
                        if !usedEnglishIndices.contains(englishIndex) {
                            bestEnglish = englishDef.text
                            usedEnglishIndices.insert(englishIndex)
                            break
                        }
                    }
                    
                    let result: [String: Any] = [
                        "character": simplifiedTerm,
                        "originalCharacter": chineseTerm.text,
                        "fullText": mainTerm,
                        "definition": bestEnglish,
                        "confidence": chineseTerm.confidence,
                        "rawText": chineseTerm.text
                    ]
                    
                    results.append(result)
                    print("OCR DEBUG - FALLBACK ENTRY: '\(simplifiedTerm)' with '\(bestEnglish)'")
                }
            }
        }
        
        print("OCR DEBUG - Final results count: \(results.count)")
        return results
    }
    
    private func isNumberedVocabEntry(_ text: String) -> Bool {
        // Check for patterns like "1.", "2)", "1", "一、", etc.
        let numberPatterns = [
            "^\\d+[.)、]",  // 1. 2) 3、
            "^\\d+\\s",      // "1 " "2 "
            "^[一二三四五六七八九十]+[、.]"  // 一、二、
        ]
        
        for pattern in numberPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               regex.firstMatch(in: text, range: NSRange(location: 0, length: text.count)) != nil {
                return true
            }
        }
        
        return false
    }
    
    private func containsChineseCharacters(_ text: String) -> Bool {
        let chinesePattern = "[\u{4e00}-\u{9fff}\u{3400}-\u{4dbf}]+"
        if let regex = try? NSRegularExpression(pattern: chinesePattern, options: []) {
            return regex.firstMatch(in: text, range: NSRange(location: 0, length: text.count)) != nil
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
        let chinesePattern = "[\u{4e00}-\u{9fff}\u{3400}-\u{4dbf}]+(?:/[\u{4e00}-\u{9fff}\u{3400}-\u{4dbf}]+)?"
        
        if let regex = try? NSRegularExpression(pattern: chinesePattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            for match in matches {
                let chineseText = (text as NSString).substring(with: match.range)
                if chineseText.count >= 2 {  // Prefer multi-character terms
                    return chineseText
                }
            }
            
            // If no multi-character term, return the first match
            if let firstMatch = matches.first {
                return (text as NSString).substring(with: firstMatch.range)
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