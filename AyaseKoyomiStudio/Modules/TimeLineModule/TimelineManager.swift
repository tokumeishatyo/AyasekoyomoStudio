import Foundation
import SwiftUI
import Combine
import AVFoundation
import UniformTypeIdentifiers

@MainActor
final class TimelineManager: ObservableObject {
    @Published var blocks: [ScriptBlock] = []
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String? = nil
    
    // APIキー（UIから受け取る）
    var apiKey: String = ""
    
    init() {
        blocks = [
            ScriptBlock(text: "こんにちは！", emotion: .happy),
            ScriptBlock(text: "ここでは感情を変えるテストをします。", emotion: .neutral),
            ScriptBlock(text: "怒った顔もできますよ！", emotion: .angry),
            ScriptBlock(text: "ちゃんと反映されるかな？", emotion: .happy)
        ]
    }
    
    // MARK: - CRUD
    func addBlock() { blocks.append(ScriptBlock()) }
    func removeBlock(at index: Int) { blocks.remove(at: index) }
    func moveBlock(from source: IndexSet, to destination: Int) { blocks.move(fromOffsets: source, toOffset: destination) }
    
    // MARK: - 🎬 監督機能 (Director)
    
    func compileAndExport() async {
        guard !apiKey.isEmpty else {
            errorMessage = "APIキーを入力してください"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        do {
            print("🎬 監督: 制作開始。ブロック数: \(blocks.count)")
            
            // 1. 各ブロックの音声を生成し、データを結合する
            var masterAudioData = Data()
            var scenes: [VideoScene] = []
            var currentTime: Double = 0.0
            
            // ひとつずつ順番に処理 (API制限に注意しつつ)
            for (index, block) in blocks.enumerated() {
                if block.text.isEmpty { continue }
                
                print("🎙️ 生成中 (\(index + 1)/\(blocks.count)): \(block.text)")
                
                // A. 音声生成
                let audioData = try await GeminiClient.shared.generateAudio(text: block.text, apiKey: apiKey)
                
                // B. 音声の長さ(秒)を測る
                let duration = try getAudioDuration(data: audioData)
                
                // C. シーンデータを作成 (開始時間〜終了時間 + 感情)
                let scene = VideoScene(
                    startTime: currentTime,
                    endTime: currentTime + duration,
                    emotion: block.emotion.rawValue // "😊 笑顔" などを渡す
                )
                scenes.append(scene)
                
                // D. データを連結・時間を進める
                masterAudioData.append(audioData)
                currentTime += duration
                
                // ※連続API呼び出しのエラー回避のため、少しだけ待機
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
            }
            
            print("🎞️ シーン構築完了: 総時間 \(String(format: "%.2f", currentTime))秒")
            
            // 2. 動画書き出し (シーン情報も渡す！)
            print("🎥 動画レンダリング中...")
            let videoURL = try await VideoExportManager.shared.exportVideo(audioData: masterAudioData, scenes: scenes)
            
            // 3. 保存
            showSavePanel(for: videoURL)
            
        } catch {
            print("❌ エラー: \(error.localizedDescription)")
            errorMessage = "制作失敗: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
    
    // MARK: - Helper: 音声データの長さを測る
    
    /// バイナリデータの音声を一時ファイルに書き出して、AVAudioFileで長さを正確に測る
    private func getAudioDuration(data: Data) throws -> Double {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp3")
        try data.write(to: tempURL)
        
        let audioFile = try AVAudioFile(forReading: tempURL)
        let duration = Double(audioFile.length) / audioFile.processingFormat.sampleRate
        
        try? FileManager.default.removeItem(at: tempURL)
        return duration
    }
    
    // MARK: - Helper: 保存パネル
    
    private func showSavePanel(for tempURL: URL) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.mpeg4Movie]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "動画を保存"
        savePanel.nameFieldStringValue = "TimelineVideo.mp4"
        
        savePanel.begin { response in
            if response == .OK, let targetURL = savePanel.url {
                do {
                    if FileManager.default.fileExists(atPath: targetURL.path) {
                        try FileManager.default.removeItem(at: targetURL)
                    }
                    try FileManager.default.moveItem(at: tempURL, to: targetURL)
                    NSWorkspace.shared.open(targetURL)
                } catch {
                    print("❌ 保存失敗: \(error)")
                }
            }
        }
    }
}
