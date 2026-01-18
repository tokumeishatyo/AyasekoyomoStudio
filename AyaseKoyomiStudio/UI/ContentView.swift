import SwiftUI

struct ContentView: View {
    @StateObject private var avatarManager = AvatarManager()
    
    var body: some View {
        HSplitView {
            TimelineView()
                .frame(minWidth: 500)
            
            VStack {
                Spacer()
                AvatarView(avatarManager: avatarManager)
                Spacer()
            }
            .frame(minWidth: 300)
            .background(Color(NSColor.windowBackgroundColor))
        }
    }
}

#Preview {
    ContentView()
}