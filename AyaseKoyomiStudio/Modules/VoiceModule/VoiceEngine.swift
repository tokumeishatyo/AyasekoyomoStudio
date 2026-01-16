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
    private var simulationTimer: Timer?
    private var simulationElapsed: TimeInterval = 0
    
    // MARK: - Simulation Constants
    
    private let simulationDuration: TimeInterval = 3.0
    private let simulationInterval: TimeInterval = 0.05
    
    // MARK: - Public Methods
    
    /// Play audio from Data
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
        }
    }
    
    /// Simulate playback for debugging (no audio file required)
    func simulatePlayback() {
        stop()
        
        simulationElapsed = 0
        
        // 【修正】scheduledTimerではなく、Timer(...)で作ってからRunLoopに追加する形式にする
        // これにより重複登録のリスクを完全に排除します
        let timer = Timer(timeInterval: simulationInterval, repeats: true) { [weak self] _ in
            self?.updateSimulation()
        }
        
        RunLoop.current.add(timer, forMode: .common)
        simulationTimer = timer
    }
    
    func stop() {
        stopMetering()
        stopSimulation()
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    // MARK: - Real Audio Metering
    
    private func startMetering() {
        meteringTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.updateMetering()
        }
        RunLoop.current.add(meteringTimer!, forMode: .common)
    }
    
    private func stopMetering() {
        meteringTimer?.invalidate()
        meteringTimer = nil
    }
    
    private func updateMetering() {
        guard let player = audioPlayer, player.isPlaying else {
            return
        }
        
        player.updateMeters()
        
        let decibels = player.averagePower(forChannel: 0)
        let normalizedAmplitude = normalizeDecibels(decibels)
        
        delegate?.audioAmplitudeDidUpdate(normalizedAmplitude)
    }
    
    private func normalizeDecibels(_ decibels: Float) -> Float {
        let minDecibels: Float = -50.0
        let maxDecibels: Float = 0.0
        
        if decibels < minDecibels {
            return 0.0
        }
        if decibels >= maxDecibels {
            return 1.0
        }
        
        return (decibels - minDecibels) / (maxDecibels - minDecibels)
    }
    
    // MARK: - Simulation
    
    private func stopSimulation() {
        simulationTimer?.invalidate()
        simulationTimer = nil
        simulationElapsed = 0
    }
    
    private func updateSimulation() {
        simulationElapsed += simulationInterval
        
        if simulationElapsed >= simulationDuration {
            stopSimulation()
            delegate?.audioAmplitudeDidUpdate(0.0)
            delegate?.audioDidFinishPlaying()
            return
        }
        
        // Generate random amplitude (0.0 - 1.0)
        let randomAmplitude = Float.random(in: 0.0...1.0)
        delegate?.audioAmplitudeDidUpdate(randomAmplitude)
    }
}

// MARK: - AVAudioPlayerDelegate

extension VoiceEngine: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopMetering()
        delegate?.audioAmplitudeDidUpdate(0.0)
        delegate?.audioDidFinishPlaying()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        stopMetering()
        if let error = error {
            print("VoiceEngine: Decode error - \(error.localizedDescription)")
        }
        delegate?.audioAmplitudeDidUpdate(0.0)
        delegate?.audioDidFinishPlaying()
    }
}
