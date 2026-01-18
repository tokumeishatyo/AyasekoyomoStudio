import Foundation
import SwiftUI
import Combine

@MainActor
final class SceneManager: ObservableObject {
    static let shared = SceneManager()
    
    // 背景画像の保存ディレクトリ
    private let backgroundsDirectory: URL
    
    // ★UI一覧用のパブリッシュプロパティ (これによりObservableObjectに準拠)
    @Published var availableBackgrounds: [URL] = []
    
    init() {
        // App Sandbox内のDocuments/Backgroundsを使用
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        backgroundsDirectory = docs.appendingPathComponent("Backgrounds")
        
        // ディレクトリ作成
        try? FileManager.default.createDirectory(at: backgroundsDirectory, withIntermediateDirectories: true)
        
        // 既存ファイルの読み込み
        loadBackgrounds()
    }
    
    private func loadBackgrounds() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: backgroundsDirectory, includingPropertiesForKeys: nil)
            availableBackgrounds = files.filter { $0.pathExtension.lowercased() == "png" }
        } catch {
            print("Failed to load backgrounds: \(error)")
        }
    }
    
    // MARK: - API
    
    /// プロンプトから背景画像を生成し、ローカルに保存してそのURLを返す
    func generateBackground(prompt: String) async throws -> URL {
        // 1. 画像生成 (Gemini API)
        let imageData = try await GeminiClient.shared.generateImage(prompt: prompt)
        
        // 2. ファイル名生成 (UUID)
        let fileName = UUID().uuidString + ".png"
        let fileURL = backgroundsDirectory.appendingPathComponent(fileName)
        
        // 3. 保存
        try imageData.write(to: fileURL)
        print("🖼️ 背景生成完了: \(fileURL.path)")
        
        loadBackgrounds() // リスト更新
        return fileURL
    }
    
    /// 既存の画像をインポートする (コピーを作成)
    func importBackground(from soruceURL: URL) throws -> URL {
        let fileName = UUID().uuidString + ".png" // 拡張子は画像に合わせて変更すべきだが一旦png
        let destURL = backgroundsDirectory.appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: destURL.path) {
            try FileManager.default.removeItem(at: destURL)
        }
        
        try FileManager.default.copyItem(at: soruceURL, to: destURL)
        loadBackgrounds() // リスト更新
        
        return destURL
    }
}
