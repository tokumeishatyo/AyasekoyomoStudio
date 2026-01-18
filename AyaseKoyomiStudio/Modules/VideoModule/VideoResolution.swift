import Foundation

enum VideoResolution: String, CaseIterable, Codable, Identifiable {
    case landscape // 1920x1080
    case square    // 1080x1080
    
    var id: String { rawValue }
    
    var size: CGSize {
        switch self {
        case .landscape:
            return CGSize(width: 1920, height: 1080)
        case .square:
            return CGSize(width: 1080, height: 1080)
        }
    }
    
    var name: String {
        switch self {
        case .landscape: "横長 (16:9)"
        case .square: "正方形 (1:1)"
        }
    }
}
