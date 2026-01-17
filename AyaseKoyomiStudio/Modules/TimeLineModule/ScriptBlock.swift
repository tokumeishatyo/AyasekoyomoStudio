import Foundation

// アバターの感情
enum AvatarEmotion: String, CaseIterable, Codable, Identifiable {
    case neutral = "😐 普通"
    case happy = "😊 笑顔"
    case angry = "😠 怒り"
    case sad = "😢 悲しみ"
    
    var id: String { self.rawValue }
}

// 1つのセリフブロック
struct ScriptBlock: Identifiable, Codable {
    let id: UUID
    var text: String
    var emotion: AvatarEmotion
    
    // 生成された音声データ
    var generatedAudio: Data?
    
    // ★この init がないと TimelineManager でエラーになります
    init(text: String = "", emotion: AvatarEmotion = .neutral) {
        self.id = UUID()
        self.text = text
        self.emotion = emotion
        self.generatedAudio = nil
    }
}
