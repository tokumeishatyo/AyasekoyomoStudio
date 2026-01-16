# プロジェクトルール

## 開発フロー
- コードのコピーアンドペーストとビルドは人間が行う
- Claudeはコードを出力するのみ

---

## 現在の状況 (LV1完了)

### 完了済みモジュール
1. **VoiceModule**
   - `VoiceEngine.swift` - 音声再生 + 音量メータリング + シミュレーションモード

2. **AvatarModule**
   - `AvatarManager.swift` - 音量→口形状(MouthState)変換、VoiceEngineを所有

3. **AIInfra**
   - `APIKeyManager.swift` - APIキー管理
   - `GeminiClient.swift` - Gemini API (テキスト生成) + Google Cloud TTS (音声生成)

4. **UI**
   - `ContentView.swift` - APIキー入力、プロンプト入力、生成フロー統合
   - `Components/AvatarView.swift` - 口パクアニメーション表示

### 実装済み機能
- リップシンク (音量に応じた口形状変化: closed/open/wide)
- シミュレーション再生 (デバッグ用)
- Gemini APIでスクリプト生成
- Google Cloud TTSで音声生成
- 生成した音声でアバターが口パク

---

## LV2 開始時のタスク

### 次のステップ候補
1. **SceneModule** - 背景レイヤーの生成と管理
2. **TimelineModule** - 動画全体の構成データ（絵コンテ）管理
3. **ExportModule** - 動画(.mp4)と字幕(.srt)の生成
4. **APIKeyManagerの改善** - 画面入力値を反映できるようにする
5. **キャラクター画像アセット** - SF Symbolsから実際の画像へ

### 依存ライブラリ
- `GoogleGenerativeAI` (Swift Package Manager)

### リポジトリ
- https://github.com/tokumeishatyo/AyasekoyomoStudio.git
