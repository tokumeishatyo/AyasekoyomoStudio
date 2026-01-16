import SwiftUI
import AVFoundation

struct ContentView: View {
    
    // MARK: - Properties
    
    @StateObject private var avatarManager = AvatarManager()
    
    // 保存せず、アプリ起動中だけ保持する変数
    @State private var inputApiKey: String = ""
    
    @State private var promptText: String = "こんにちは！自己紹介してください。"
    @State private var isGenerating = false
    @State private var errorMessage: String?
    
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
                    
                    // SecureField: 入力した文字は隠されます
                    SecureField("Paste your API Key here", text: $inputApiKey)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: inputApiKey) { oldValue, newValue in
                            // 入力されるたびにマネージャーに渡す（保存はしない）
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
        
        Task {
            do {
                // 1. Geminiでテキスト生成
                print("Gemini: Generating text...")
                let script = try await GeminiClient.shared.generateScript(prompt: promptText)
                
                // 2. TTSで音声生成
                print("TTS: Generating audio...")
                let audioData = try await GeminiClient.shared.generateSpeech(text: script)
                
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
}

#Preview {
    ContentView()
}
