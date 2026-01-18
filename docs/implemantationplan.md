実装計画 - キャッシュ機能 (非機能要件)
音声データおよび画像データのローカルキャッシュ機能を実装し、API呼び出し回数の削減とパフォーマンス向上を図ります。

目標
音声キャッシュ: 同じテキスト・設定での音声生成時は、ローカル保存されたデータを使用する。
画像キャッシュ: 同じプロンプト・設定での画像生成時は、ローカル保存されたデータを使用する。
実装内容
1. 新規ユーティリティ作成
[NEW] 
CryptoUtils.swift
キャッシュキー生成のために、文字列のハッシュ化（SHA256）機能を提供します。
String の拡張として sha256Hash プロパティなどを実装。
2. キャッシュ管理クラス作成
[NEW] 
CacheManager.swift
Library/Caches 以下の専用ディレクトリを管理。
Audio: Library/Caches/AyaseKoyomiStudio/Audio
Images: Library/Caches/AyaseKoyomiStudio/Images
API:
func getAudio(key: String) -> Data?
func saveAudio(_ data: Data, key: String)
func getImage(key: String) -> Data?
func saveImage(_ data: Data, key: String)
3. GeminiClientへの統合
[MODIFY] 
GeminiClient.swift
generateAudio(text:apiKey:):
キャッシュキー生成: SHA256("voice_ja-JP-Neural2-B_" + text) (など)
CacheManager に確認 → あれば返却。
なければAPI呼び出し → 結果を CacheManager に保存してから返却。
generateImage(prompt:):
キャッシュキー生成: SHA256("model_imagen-4.0_" + prompt)
CacheManager に確認 → あれば返却。
なければAPI呼び出し → 結果を CacheManager に保存してから返却。
検証計画
動作確認
初回: テキストを入力して「動画書き出し」あるいは音声生成を行い、API経由で生成されることを確認（ログ等が無いとわからないが、ネットワーク通信が発生する）。
2回目: 同じテキストで再度実行した際、瞬時に完了すること（キャッシュヒット）を確認する。
ログ(print)に「キャッシュから取得」と出力させることで確認を容易にする。