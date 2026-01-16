import SwiftUI
import AVFoundation

struct ContentView: View {
    
    // MARK: - Properties
    
    @StateObject private var avatarManager = AvatarManager()
    private let voiceEngine = VoiceEngine()
    
    @State private var isPlaying = false
    @State private var isGenerating = false // 生成中インジケータ用
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Avatar
            AvatarView(avatarManager: avatarManager)
            
            Spacer()
            
            // Test button
            Button(action: playTestBeep) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .controlSize(.small)
                            .colorScheme(.dark)
                        Text("生成中...")
                    } else {
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                        Text(isPlaying ? "停止" : "テスト再生")
                    }
                }
                .font(.headline)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(isPlaying ? Color.red : (isGenerating ? Color.gray : Color.blue))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(isPlaying || isGenerating)
            
            Spacer()
        }
        .frame(minWidth: 400, minHeight: 400)
        .onAppear {
            setupVoiceEngine()
        }
    }
    
    // MARK: - Setup
    
    private func setupVoiceEngine() {
        voiceEngine.delegate = avatarManager
    }
    
    // MARK: - Actions
    
    private func playTestBeep() {
        guard !isPlaying && !isGenerating else { return }
        
        isGenerating = true
        
        // 【修正1】重いWAV生成処理をバックグラウンド(裏側)で実行する
        DispatchQueue.global(qos: .userInitiated).async {
            
            // 音声データの生成（数秒かかる可能性がある）
            let audioData = self.generateBeepWAV(frequency: 440, duration: 2.0, sampleRate: 44100)
            
            // 生成が終わったらメインスレッド(画面側)に戻って再生する
            DispatchQueue.main.async {
                self.isGenerating = false
                
                if let data = audioData {
                    self.isPlaying = true
                    self.voiceEngine.play(audioData: data)
                    
                    // 再生が終わる頃にフラグを戻す
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        self.isPlaying = false
                    }
                }
            }
        }
    }
    
    // MARK: - Beep Generator
    
    /// Generate WAV audio data with sine wave
    private func generateBeepWAV(frequency: Double, duration: Double, sampleRate: Int) -> Data? {
        let numSamples = Int(duration * Double(sampleRate))
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let byteRate = Int32(sampleRate * Int(numChannels) * Int(bitsPerSample / 8))
        let blockAlign = Int16(numChannels * (bitsPerSample / 8))
        let dataSize = Int32(numSamples * Int(numChannels) * Int(bitsPerSample / 8))
        let fileSize = 36 + dataSize
        
        var data = Data()
        
        // 【修正2】メモリ確保を効率化（頻繁な再確保を防ぐ）
        data.reserveCapacity(Int(fileSize))
        
        // Helper to append data safely
        func append<T>(_ value: T) {
            var val = value
            withUnsafeBytes(of: &val) { buffer in
                data.append(buffer.bindMemory(to: UInt8.self))
            }
        }
        
        // RIFF header
        data.append(contentsOf: "RIFF".utf8)
        append(fileSize.littleEndian)
        data.append(contentsOf: "WAVE".utf8)
        
        // fmt chunk
        data.append(contentsOf: "fmt ".utf8)
        append(Int32(16).littleEndian) // chunk size
        append(Int16(1).littleEndian)  // PCM format
        append(numChannels.littleEndian)
        append(Int32(sampleRate).littleEndian)
        append(byteRate.littleEndian)
        append(blockAlign.littleEndian)
        append(bitsPerSample.littleEndian)
        
        // data chunk
        data.append(contentsOf: "data".utf8)
        append(dataSize.littleEndian)
        
        // Generate sine wave
        let baseAmplitude: Double = 32767 * 0.8
        
        for i in 0..<numSamples {
            let time = Double(i) / Double(sampleRate)
            
            // Add amplitude modulation for more visible mouth movement
            let amplitudeModulation = 0.5 + 0.5 * sin(2.0 * .pi * 8.0 * time)
            let currentAmplitude = baseAmplitude * amplitudeModulation
            
            let sample = sin(2.0 * .pi * frequency * time) * currentAmplitude
            let intSample = Int16(max(-32768, min(32767, sample)))
            
            // Append sample optimized
            append(intSample.littleEndian)
        }
        
        return data
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
