import Foundation
import Combine

// MARK: - MouthState

enum MouthState {
    case closed
    case open
    case wide
}

// MARK: - EyesState

enum EyesState {
    case open
    case closed
    case smile
}

// MARK: - AvatarManager

final class AvatarManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var mouthState: MouthState = .closed
    @Published private(set) var eyesState: EyesState = .open // ★追加
    @Published private(set) var isPlaying: Bool = false
    
    // MARK: - Private Properties
    
    private let voiceEngine = VoiceEngine()
    private var blinkTimer: Timer?
    
    // MARK: - Threshold Constants
    
    private let closedThreshold: Float = 0.1
    private let wideThreshold: Float = 0.6
    
    // MARK: - Initializer
    
    override init() {
        super.init()
        voiceEngine.delegate = self
        startBlinking() // ★初期化時に瞬き開始
    }
    
    deinit {
        blinkTimer?.invalidate()
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
    
    // MARK: - Blinking Logic
    
    private func startBlinking() {
        scheduleNextBlink()
    }
    
    private func scheduleNextBlink() {
        // 3.0〜5.0秒のランダムな間隔
        let interval = Double.random(in: 3.0...5.0)
        
        blinkTimer?.invalidate()
        blinkTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.blink()
        }
    }
    
    private func blink() {
        // 目を閉じる
        eyesState = .closed
        
        // 0.1秒後に開ける
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            self.eyesState = .open
            self.scheduleNextBlink() // 次の瞬きをスケジュール
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
