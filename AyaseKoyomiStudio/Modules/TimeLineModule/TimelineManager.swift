import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers

@MainActor
final class TimelineManager: ObservableObject {
    @Published var blocks: [ScriptBlock] = []
    
    // 生成中かどうか
    @Published var isProcessing: Bool = false
    // エラーメッセージ用
    @Published var errorMessage: String? = nil
    
    // APIキー（UIから受け取る）
    var apiKey: String = ""
    
    init() {
        blocks = [
            ScriptBlock(text: "こんにちは！"),
            ScriptBlock(text: "これはタイムライン機能のテストです。"),
            ScriptBlock(text: "うまく動画になるでしょうか？")
        ]
    }
    
    // MARK: - CRUD (変更なし)
    func addBlock() { blocks.append(ScriptBlock()) }
    func removeBlock(at index: Int) { blocks.remove(at: index) }
    func moveBlock(from source: IndexSet, to destination: Int) { blocks.move(fromOffsets: source, toOffset: destination) }
    
    // MARK: - 🎬 監督機能 (Director)
    
    /// すべてのセリフを繋げて動画を作成する
    func compileAndExport() async {
        guard !apiKey.isEmpty else {
            errorMessage = "APIキーを入力してください"
            return
        }
        
        isProcessing = true
        errorMessage = nil
        
        do {
            // 1. 脚本の結合
            // 全ブロックのテキストを「。」で繋いで1つの文章にします
            // ※ 将来的にはブロックごとに音声を生成して結合する方式に進化させます
            let fullScript = blocks.map { $0.text }.joined(separator: "。")
            print("📜 脚本: \(fullScript)")
            
            // 2. 音声生成 (GeminiClientを利用)
            // ※ お手持ちのGeminiClientの実装に合わせて呼び出し名を調整してください
            print("🎙️ 音声生成中...")
            let audioData = try await GeminiClient.shared.generateAudio(text: fullScript, apiKey: apiKey)
            
            // 3. 動画書き出し (VideoExportManagerを利用)
            print("🎥 動画レンダリング中...")
            let videoURL = try await VideoExportManager.shared.exportVideo(audioData: audioData)
            
            // 4. 保存パネルを開く
            showSavePanel(for: videoURL)
            
        } catch {
            print("❌ エラー: \(error.localizedDescription)")
            errorMessage = "エラー: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
    
    /// 保存パネルを表示してファイルを移動する
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
                    print("✅ 保存完了: \(targetURL.path)")
                    
                    // 完了時にファイルを開く
                    NSWorkspace.shared.open(targetURL)
                } catch {
                    print("❌ 保存失敗: \(error)")
                }
            }
        }
    }
}
