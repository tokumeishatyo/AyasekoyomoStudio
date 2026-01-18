import Foundation

struct SubtitleBlock {
    let id: Int
    let startTime: Double
    let endTime: Double
    let text: String
}

final class SubtitleManager {
    static let shared = SubtitleManager()
    private init() {}
    
    // MARK: - SRT Generation
    
    /// スクリプトブロックからSRT形式の文字列を生成する
    /// - Parameters:
    ///   - blocks: ScriptBlockの配列
    ///   - audioDurations: 各ブロックの音声長さ（秒）の配列。blocksと同じ順序・数であること。
    /// - Returns: SRTフォーマットの文字列
    func generateSRT(blocks: [ScriptBlock], audioDurations: [Double]) -> String {
        var srtOutput = ""
        var currentTime: Double = 0.0
        var counter = 1
        
        for (index, block) in blocks.enumerated() {
            if block.text.isEmpty { continue }
            
            // 音声の長さを取得 (なければデフォルト3秒などにするが、基本は渡される前提)
            let duration = index < audioDurations.count ? audioDurations[index] : 3.0
            
            let startTime = currentTime
            let endTime = currentTime + duration
            
            srtOutput += "\(counter)\n"
            srtOutput += "\(formatTime(startTime)) --> \(formatTime(endTime))\n"
            srtOutput += "\(block.text)\n\n"
            
            currentTime += duration
            counter += 1
        }
        
        return srtOutput.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Translation
    
    /// SRTの内容をGemini APIを使って翻訳する
    func translateSRT(srtContent: String) async throws -> String {
        let prompt = """
        以下のSRT (SubRip Subtitle) ファイルの内容を、タイムコードや構造を維持したまま、英語に翻訳してください。
        キャラクターのセリフなので、状況に応じて適切な口調（丁寧語、カジュアルなど）を反映してください。
        
        [SRT Start]
        \(srtContent)
        [SRT End]
        
        出力はSRT形式のテキストのみを返してください。冒頭の説明やMarkdownのコードブロック記法は不要です。
        """
        
        // GeminiClientを使用して翻訳
        // 注: generateScriptは汎用的なテキスト生成メソッドとして使用可能
        let translatedText = try await GeminiClient.shared.generateScript(prompt: prompt)
        
        // 余計な文字が含まれている場合のクリーニング（Markdown記法除去など）
        let cleaned = cleanupGeminiOutput(translatedText)
        return cleaned
    }
    
    // MARK: - Save
    
    func saveSRT(content: String, to url: URL) throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
    
    // MARK: - Helpers
    
    /// 秒数を SRT 形式 (HH:mm:ss,mmm) に変換
    private func formatTime(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let milliseconds = Int((seconds - Double(totalSeconds)) * 1000)
        
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        
        return String(format: "%02d:%02d:%02d,%03d", h, m, s, milliseconds)
    }
    
    private func cleanupGeminiOutput(_ text: String) -> String {
        var result = text
        // Markdownコードブロックの削除
        if result.starts(with: "```srt") {
            result = result.replacingOccurrences(of: "```srt", with: "")
        } else if result.starts(with: "```") {
            result = result.replacingOccurrences(of: "```", with: "")
        }
        if result.hasSuffix("```") {
            result = String(result.dropLast(3))
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
