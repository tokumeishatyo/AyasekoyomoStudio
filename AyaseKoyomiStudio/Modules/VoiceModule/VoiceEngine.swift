import Foundation
import AVFoundation

// MARK: - VoiceEngineDelegate Protocol

protocol VoiceEngineDelegate: AnyObject {
    func audioDidFinishPlaying()
    func audioAmplitudeDidUpdate(_ amplitude: Float)
}

// MARK: - VoiceEngine

final class VoiceEngine: NSObject {
    
    // MARK: - Properties
    
    weak var delegate: VoiceEngineDelegate?
    
    private var audioPlayer: AVAudioPlayer?
    private var meteringTimer: Timer?
    
    // MARK: - Public Methods
    
    func play(audioData: Data) {
        stop()
        
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.delegate = self
            audioPlayer?.isMeteringEnabled = true
            audioPlayer?.prepareToPlay()
            
            startMetering()
            audioPlayer?.play()
        } catch {
            print("VoiceEngine: Failed to initialize audio player - \(error.localizedDescription)")
            delegate?.audioDidFinishPlaying() // エラー時も終了通知を送る
        }
    }
    
    func stop() {
        stopMetering()
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    // MARK: - Private Methods
    
    private func startMetering() {
        // 約60fps (1/60 ≈ 0.016秒) で音量を監視
        meteringTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.updateMetering()
        }
        // スクロール中もタイマーを止めないようにCommonモードに追加
        if let timer = meteringTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    private func stopMetering() {
        meteringTimer?.invalidate()
        meteringTimer = nil
        delegate?.audioAmplitudeDidUpdate(0.0)
    }
    
    private func updateMetering() {
        guard let player = audioPlayer, player.isPlaying else {
            return
        }
        
        player.updateMeters()
        
        // averagePowerForChannel returns dB value (-160 to 0)
        let decibels = player.averagePower(forChannel: 0)
        
        // Normalize to 0.0 - 1.0
        let normalizedAmplitude = normalizeDecibels(decibels)
        
        delegate?.audioAmplitudeDidUpdate(normalizedAmplitude)
    }
    
    private func normalizeDecibels(_ decibels: Float) -> Float {
        // dB range: -160 (silent) to 0 (max)
        // Using -50dB as practical minimum for speech
        let minDecibels: Float = -50.0
        let maxDecibels: Float = 0.0
        
        if decibels < minDecibels {
            return 0.0
        }
        if decibels >= maxDecibels {
            return 1.0
        }
        
        // Linear interpolation
        let normalized = (decibels - minDecibels) / (maxDecibels - minDecibels)
        return normalized
    }
}

// MARK: - AVAudioPlayerDelegate

extension VoiceEngine: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopMetering()
        delegate?.audioDidFinishPlaying()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        stopMetering()
        if let error = error {
            print("VoiceEngine: Decode error - \(error.localizedDescription)")
        }
        delegate?.audioDidFinishPlaying()
    }
}