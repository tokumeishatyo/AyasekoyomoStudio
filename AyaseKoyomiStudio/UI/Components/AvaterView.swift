import SwiftUI

struct AvatarView: View {
    
    @ObservedObject var avatarManager: AvatarManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Face
            ZStack {
                // Face background
                Circle()
                    .fill(Color.yellow.opacity(0.3))
                    .frame(width: 200, height: 200)
                
                // Eyes
                HStack(spacing: 50) {
                    Eye(state: avatarManager.eyesState)
                    Eye(state: avatarManager.eyesState)
                }
                .offset(y: -20)
                
                // Mouth
                MouthView(state: avatarManager.mouthState)
                    .offset(y: 40)
            }
            
            // Debug label
            Text(mouthStateText)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 20)
        }
    }
    
    private var mouthStateText: String {
        switch avatarManager.mouthState {
        case .closed:
            return "Mouth: Closed"
        case .open:
            return "Mouth: Open"
        case .wide:
            return "Mouth: Wide"
        }
    }
}

// MARK: - Eye Component

private struct Eye: View {
    let state: EyesState
    
    var body: some View {
        switch state {
        case .open:
            Ellipse()
                .fill(Color.black)
                .frame(width: 16, height: 20)
        case .closed:
            // 閉じた目 (横線)
            Rectangle()
                .fill(Color.black)
                .frame(width: 18, height: 2)
        case .smile:
            // 笑った目 (アーチ)
            Circle()
                .trim(from: 0.0, to: 0.5)
                .stroke(Color.black, lineWidth: 2)
                .rotationEffect(.degrees(180))
                .frame(width: 18, height: 18)
        }
    }
}

// MARK: - Mouth Component

private struct MouthView: View {
    
    let state: MouthState
    
    var body: some View {
        switch state {
        case .closed:
            // Closed mouth - horizontal line
            Capsule()
                .fill(Color.red.opacity(0.8))
                .frame(width: 40, height: 6)
            
        case .open:
            // Open mouth - small ellipse
            Ellipse()
                .fill(Color.red.opacity(0.8))
                .frame(width: 30, height: 20)
                .overlay(
                    Ellipse()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 24, height: 14)
                )
            
        case .wide:
            // Wide open mouth - large ellipse
            Ellipse()
                .fill(Color.red.opacity(0.8))
                .frame(width: 50, height: 40)
                .overlay(
                    Ellipse()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 40, height: 30)
                )
        }
    }
}

// MARK: - Preview

#Preview {
    AvatarView(avatarManager: AvatarManager())
}
