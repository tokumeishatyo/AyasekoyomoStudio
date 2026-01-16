import Foundation

class APIKeyManager {
    // 書き換え可能な変数として定義 (初期値は空)
    static var apiKey: String = ""
    
    // キーがセットされているか確認する便利プロパティ
    static var hasKey: Bool {
        return !apiKey.isEmpty
    }
}
