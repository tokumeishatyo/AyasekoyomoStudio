import Foundation
import Combine

// MARK: - MouthState

enum MouthState {
    case closed
    case open
    case wide
}

// MARK: - AvatarManager

final class AvatarManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var mouthState: MouthState = .closed
    @Published private(set) var isPlaying: Bool = false
    
    // MARK: - Private Properties
    
    private let voiceEngine = VoiceEngine()
    
    // MARK: - Threshold Constants
    
    private let closedThreshold: Float = 0.1
    private let wideThreshold: Float = 0.6
    
    // MARK: - Initializer
    
    override init() {
        super.init()
        voiceEngine.delegate = self
    }
    
    // MARK: - Public Methods
    
    /// Start simulated playback for testing lip-sync
    func playTest() {
        guard !isPlaying else { return }
        isPlaying = true
        voiceEngine.simulatePlayback()
    }
    
    /// Play actual audio data
    func speak(audioData: Data) {
        guard !isPlaying else { return }
        isPlaying = true
        voiceEngine.play(audioData: audioData)
    }
    
    /// Stop current playback
    func stop() {
        voiceEngine.stop()
        isPlaying = false
        mouthState = .closed
    }
    
    // MARK: - Private Methods
    
    private func updateMouthState(from amplitude: Float) {
        let newState: MouthState
        
        if amplitude < closedThreshold {
            newState = .closed
        } else if amplitude < wideThreshold {
            newState = .open
        } else {
            newState = .wide
        }
        
        if mouthState != newState {
            mouthState = newState
        }
    }
}

// MARK: - VoiceEngineDelegate

extension AvatarManager: VoiceEngineDelegate {
    
    func audioAmplitudeDidUpdate(_ amplitude: Float) {
        DispatchQueue.main.async { [weak self] in
            self?.updateMouthState(from: amplitude)
        }
    }
    
    func audioDidFinishPlaying() {
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false
            self?.mouthState = .closed
        }
    }
}
