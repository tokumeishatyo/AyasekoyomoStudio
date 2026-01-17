import Foundation
// import GoogleGenerativeAI ← SDKはもう使いません

// MARK: - GeminiClientError

enum GeminiClientError: LocalizedError {
    case invalidResponse
    case noTextGenerated
    case apiRequestFailed(String)
    case invalidData
    case apiKeyMissing
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        case .noTextGenerated:
            return "テキストが生成されませんでした"
        case .apiRequestFailed(let message):
            return "APIリクエストエラー: \(message)"
        case .invalidData:
            return "データの解析に失敗しました"
        case .apiKeyMissing:
            return "APIキーが設定されていません"
        }
    }
}

// MARK: - GeminiClient

final class GeminiClient {
    
    static let shared = GeminiClient()
    
    // ターミナルで成功したモデル名を設定
    private let modelName = "gemini-2.5-flash"
    
    private init() {}
    
    // MARK: - 機能A: テキスト生成 (Gemini REST API)
    
    func generateScript(prompt: String) async throws -> String {
        // 1. APIキーチェック
        guard !APIKeyManager.apiKey.isEmpty else {
            throw GeminiClientError.apiKeyMissing
        }
        
        // 2. URL構築 (ターミナルと同じ v1beta エンドポイントを使用)
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent"
        guard let url = URL(string: "\(endpoint)?key=\(APIKeyManager.apiKey)") else {
            throw GeminiClientError.apiRequestFailed("URLが無効です")
        }
        
        // 3. リクエストボディ作成
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        // 4. リクエスト作成
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // 5. 通信実行
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiClientError.invalidResponse
        }
        
        // エラーなら詳細を表示
        guard httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown"
            print("Gemini API Error: \(errorText)") // デバッグ用にコンソールに出力
            throw GeminiClientError.apiRequestFailed("Status \(httpResponse.statusCode): \(errorText)")
        }
        
        // 6. レスポンス解析
        // ターミナルで確認したJSON構造: candidates[0].content.parts[0].text
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiClientError.noTextGenerated
        }
        
        return text
    }
    
    // MARK: - 機能B: 音声生成 (Google Cloud TTS REST API)
    
    func generateSpeech(text: String, voiceStyle: String = "ja-JP-Neural2-B") async throws -> Data {
        guard !APIKeyManager.apiKey.isEmpty else {
            throw GeminiClientError.apiKeyMissing
        }
        
        let ttsEndpoint = "https://texttospeech.googleapis.com/v1/text:synthesize"
        guard let url = URL(string: "\(ttsEndpoint)?key=\(APIKeyManager.apiKey)") else {
            throw GeminiClientError.apiRequestFailed("Invalid URL")
        }
        
        let requestBody: [String: Any] = [
            "input": ["text": text],
            "voice": ["languageCode": "ja-JP", "name": voiceStyle],
            "audioConfig": ["audioEncoding": "MP3", "sampleRateHertz": 44100]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(APIKeyManager.apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown"
            throw GeminiClientError.apiRequestFailed("TTS Error: \(errorText)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let audioContent = json["audioContent"] as? String,
              let audioData = Data(base64Encoded: audioContent) else {
            throw GeminiClientError.invalidData
        }
        
        return audioData
    }
    /// Google Text-to-Speech API を叩いて音声を生成する
    func generateAudio(text: String, apiKey: String) async throws -> Data {
        // エンドポイント (Google Cloud Text-to-Speech)
        let urlString = "https://texttospeech.googleapis.com/v1/text:synthesize?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        // リクエストボディ作成
        let parameters: [String: Any] = [
            "input": ["text": text],
            "voice": [
                "languageCode": "ja-JP",
                "name": "ja-JP-Neural2-B" // 女性の声 (Neural2推奨)
                // "name": "ja-JP-Neural2-C" // 男性の声ならこちら
            ],
            "audioConfig": [
                "audioEncoding": "MP3",
                "speakingRate": 1.0,
                "pitch": 0.0,
                "sampleRateHertz": 44100
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        
        // APIコール
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            // エラー詳細を出力
            if let errorText = String(data: data, encoding: .utf8) {
                print("TTS Error: \(errorText)")
            }
            throw URLError(.badServerResponse)
        }
        
        // レスポンスの解析 (Base64文字列が入っている)
        let decoder = JSONDecoder()
        let ttsResponse = try decoder.decode(TTSResponse.self, from: data)
        
        // Base64をData型に変換
        guard let audioData = Data(base64Encoded: ttsResponse.audioContent) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        return audioData
    }
    
    // ▼▼▼ ファイルの末尾またはクラスの外に配置 ▼▼▼
    
    // TTS APIのレスポンスを受け取るための構造体
    struct TTSResponse: Codable {
        let audioContent: String
    }
}
