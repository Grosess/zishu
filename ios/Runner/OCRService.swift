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
        var results: [[String: Any]] = []
        
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            
            let text = topCandidate.string
            let boundingBox = observation.boundingBox
            
            let lineData = self.parseVocabLine(text)
            
            if !lineData.isEmpty {
                var data = lineData
                data["boundingBox"] = [
                    "x": boundingBox.origin.x,
                    "y": boundingBox.origin.y,
                    "width": boundingBox.width,
                    "height": boundingBox.height
                ]
                data["confidence"] = topCandidate.confidence
                results.append(data)
            }
        }
        
        return results
    }
    
    private func parseVocabLine(_ text: String) -> [String: Any] {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Filter out non-vocabulary items
        if isHeaderOrNonVocab(cleanedText) {
            return [:]
        }
        
        // Handle row-based format: character | pronunciation | english
        // Try to split by common separators first
        let separators = ["\t", "  ", "   ", "|", "｜"]
        var components: [String] = []
        
        for separator in separators {
            let parts = cleanedText.components(separatedBy: separator).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if parts.count >= 2 {
                components = parts
                break
            }
        }
        
        // If no clear separation found, use regex approach
        if components.isEmpty {
            return parseVocabLineRegex(cleanedText)
        }
        
        // Extract Chinese character (first component)
        let chinesePattern = "[\u{4e00}-\u{9fff}\u{3400}-\u{4dbf}\u{20000}-\u{2a6df}\u{2a700}-\u{2b73f}\u{2b740}-\u{2b81f}\u{2b820}-\u{2ceaf}\u{2ceb0}-\u{2ebef}\u{30000}-\u{3134f}]+"
        guard let chineseRegex = try? NSRegularExpression(pattern: chinesePattern, options: []) else {
            return [:]
        }
        
        var firstCharacter = ""
        var chineseText = ""
        
        // Look for Chinese characters in the first few components
        for component in components.prefix(2) {
            let nsComponent = component as NSString
            let matches = chineseRegex.matches(in: component, options: [], range: NSRange(location: 0, length: nsComponent.length))
            
            if let firstMatch = matches.first {
                chineseText = nsComponent.substring(with: firstMatch.range)
                firstCharacter = String(chineseText.prefix(1))
                break
            }
        }
        
        guard !firstCharacter.isEmpty else {
            return [:]
        }
        
        // Additional validation: ensure we have a meaningful English definition
        let simplifiedCharacter = convertToSimplified(firstCharacter)
        
        // Extract English definition (usually the last component or after pinyin)
        var definition = ""
        if components.count >= 3 {
            // Assume format: character | pinyin | english
            definition = components[2].trimmingCharacters(in: .whitespacesAndNewlines)
        } else if components.count >= 2 {
            // Try to find English in the second component
            let secondComponent = components[1]
            definition = extractEnglishFromText(secondComponent)
        }
        
        // Clean up the definition
        definition = cleanDefinition(definition)
        
        // Filter out if definition is too short or doesn't look like English
        if definition.count < 2 || !hasValidEnglishDefinition(definition) {
            return [:]
        }
        
        return [
            "character": simplifiedCharacter,
            "originalCharacter": firstCharacter,
            "fullText": chineseText,
            "definition": definition,
            "rawText": text
        ]
    }
    
    private func isHeaderOrNonVocab(_ text: String) -> Bool {
        let lowercaseText = text.lowercased()
        
        // Common header patterns to filter out
        let headerPatterns = [
            "中文", "ap-ib", "ib", "ap", "名字", "姓名", "name",
            "chinese", "vocabulary", "vocab", "lesson", "chapter",
            "unit", "page", "练习", "練習", "practice", "exercise"
        ]
        
        for pattern in headerPatterns {
            if lowercaseText.contains(pattern) {
                return true
            }
        }
        
        // Filter out lines that are mostly numbers
        let numberPattern = "\\d"
        if let numberRegex = try? NSRegularExpression(pattern: numberPattern, options: []) {
            let numberMatches = numberRegex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            let numberRatio = Double(numberMatches.count) / Double(text.count)
            if numberRatio > 0.5 {
                return true
            }
        }
        
        // Filter out very short lines (likely not vocabulary)
        if text.count < 3 {
            return true
        }
        
        // Filter out lines that don't have Chinese characters
        let chinesePattern = "[\u{4e00}-\u{9fff}\u{3400}-\u{4dbf}]"
        if let chineseRegex = try? NSRegularExpression(pattern: chinesePattern, options: []) {
            let chineseMatches = chineseRegex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            if chineseMatches.isEmpty {
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
        let firstCharacter = String(chineseText.prefix(1))
        let simplifiedCharacter = convertToSimplified(firstCharacter)
        
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
        
        // Remove pinyin (tone marked and unmarked)
        let pinyinPattern = "[a-züāáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ]+[\\s]*"
        if let pinyinRegex = try? NSRegularExpression(pattern: pinyinPattern, options: .caseInsensitive) {
            var result = pinyinRegex.stringByReplacingMatches(
                in: cleanedText,
                options: [],
                range: NSRange(location: 0, length: (cleanedText as NSString).length),
                withTemplate: ""
            )
            
            // If we have meaningful English text after removing pinyin, use it
            result = result.trimmingCharacters(in: .whitespacesAndNewlines)
            if result.count > 2 && containsEnglishText(result) {
                return result
            }
        }
        
        // If pinyin removal didn't work well, try to find English text patterns
        let englishPattern = "[a-zA-Z][a-zA-Z\\s,;.'\"\\-()]*[a-zA-Z]"
        if let englishRegex = try? NSRegularExpression(pattern: englishPattern, options: []) {
            let matches = englishRegex.matches(in: cleanedText, options: [], range: NSRange(location: 0, length: (cleanedText as NSString).length))
            
            if let longestMatch = matches.max(by: { $0.range.length < $1.range.length }) {
                let englishText = (cleanedText as NSString).substring(with: longestMatch.range)
                if englishText.count > 2 {
                    return englishText.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        return cleanedText
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