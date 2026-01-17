import SwiftUI
import AVFoundation

struct ContentView: View {
    
    // MARK: - Properties
    
    @StateObject private var avatarManager = AvatarManager()
    
    // APIキー入力用
    @State private var inputApiKey: String = ""
    
    // UI状態管理
    @State private var promptText: String = "こんにちは！自己紹介してください。"
    @State private var isGenerating = false
    @State private var errorMessage: String?
    
    // ★★★ 今回のエラーの原因：ここが抜けていました ★★★
    // 動画保存用に、生成された音声データを一時的に持っておく変数
    @State private var generatedAudioData: Data? = nil
    @State private var isExporting = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 30) {
            
            // --- 1. API Key Input Area ---
            VStack(alignment: .leading, spacing: 8) {
                Text("Google API Key")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(.gray)
                    
                    SecureField("Paste your API Key here", text: $inputApiKey)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: inputApiKey) { oldValue, newValue in
                            APIKeyManager.apiKey = newValue
                        }
                    
                    if !inputApiKey.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            Spacer()
            
            // --- 2. Avatar Area ---
            ZStack {
                AvatarView(avatarManager: avatarManager)
                
                if isGenerating {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("AIが思考中...")
                            .font(.caption)
                            .padding(.top, 8)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
            }
            
            // Error Message
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // --- 3. Control Area ---
            VStack(spacing: 16) {
                HStack {
                    Text("Prompt:")
                        .fontWeight(.bold)
                    TextField("AIに喋らせたい内容を入力", text: $promptText)
                        .textFieldStyle(.roundedBorder)
                }
                
                // 生成ボタン
                Button(action: startGeneration) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("生成・再生スタート")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(inputApiKey.isEmpty || isGenerating ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(inputApiKey.isEmpty || isGenerating)
                .buttonStyle(.plain)
                
                // ★★★ 動画保存ボタン ★★★
                if generatedAudioData != nil {
                    Button(action: saveVideo) {
                        HStack {
                            if isExporting {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                            }
                            Text(isExporting ? "書き出し中..." : "動画として保存 (MP4)")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isExporting ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isExporting)
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
        }
        .frame(minWidth: 500, minHeight: 600)
    }
    
    // MARK: - Logic
    
    private func startGeneration() {
        guard !promptText.isEmpty else { return }
        
        isGenerating = true
        errorMessage = nil
        generatedAudioData = nil // リセット
        
        Task {
            do {
                // 1. Geminiでテキスト生成
                print("Gemini: Generating text...")
                let script = try await GeminiClient.shared.generateScript(prompt: promptText)
                
                // 2. TTSで音声生成
                print("TTS: Generating audio...")
                let audioData = try await GeminiClient.shared.generateSpeech(text: script)
                
                // ★保存用にデータを保持しておく
                await MainActor.run {
                    self.generatedAudioData = audioData
                }
                
                // 3. 再生 & リップシンク開始
                print("Avatar: Speaking...")
                await MainActor.run {
                    avatarManager.speak(audioData: audioData)
                    isGenerating = false
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGenerating = false
                }
            }
        }
    }
    
    // MARK: - 動画保存処理
    private func saveVideo() {
        guard let audioData = generatedAudioData else { return }
        isExporting = true
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.mpeg4Movie]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.nameFieldStringValue = "avatar_video.mp4"
        
        savePanel.begin { response in
            if response == .OK, let targetURL = savePanel.url {
                
                Task {
                    do {
                        // Managerを使って動画を書き出し
                        let tempURL = try await VideoExportManager.shared.exportVideo(audioData: audioData)
                        
                        // 一時ファイルをユーザーの指定場所に移動 (上書き対応)
                        if FileManager.default.fileExists(atPath: targetURL.path) {
                            try? FileManager.default.removeItem(at: targetURL)
                        }
                        try FileManager.default.moveItem(at: tempURL, to: targetURL)
                        
                        await MainActor.run {
                            self.isExporting = false
                            print("保存完了: \(targetURL)")
                        }
                    } catch {
                        await MainActor.run {
                            self.isExporting = false
                            self.errorMessage = "書き出し失敗: \(error.localizedDescription)"
                        }
                    }
                }
            } else {
                isExporting = false
            }
        }
    }
}

#Preview {
    ContentView()
}
