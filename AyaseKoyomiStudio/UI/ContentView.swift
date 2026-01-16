import SwiftUI

struct ContentView: View {
    
    // MARK: - Properties
    
    @StateObject private var avatarManager = AvatarManager()
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Avatar
            AvatarView(avatarManager: avatarManager)
            
            Spacer()
            
            // Test button
            Button(action: {
                avatarManager.playTest()
            }) {
                HStack {
                    Image(systemName: avatarManager.isPlaying ? "waveform" : "play.fill")
                    Text(avatarManager.isPlaying ? "再生中..." : "テスト再生")
                }
                .font(.headline)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(avatarManager.isPlaying ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(avatarManager.isPlaying)
            
            Spacer()
        }
        .frame(minWidth: 400, minHeight: 400)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}                                             
