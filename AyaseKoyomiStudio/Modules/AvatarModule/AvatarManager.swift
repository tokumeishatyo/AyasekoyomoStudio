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
    
    // MARK: - Threshold Constants
    
    private let closedThreshold: Float = 0.1
    private let wideThreshold: Float = 0.6
    
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
        
        // Only update if state changed to reduce UI updates
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
            self?.mouthState = .closed
        }
    }
}
