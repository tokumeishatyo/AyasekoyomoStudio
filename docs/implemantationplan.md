実装計画 - SceneModule (Lv.2) 実装
ドキュメント 
docs/残作業.txt
 および 
docs/機能仕様書.md
 に基づき、未実装の SceneModule を実装し、背景画像の管理・生成・描画機能を提供します。

目標
SceneManagerの実装: 背景画像の管理（インポート・生成・保存）。
画像生成機能: Gemini API (imagen-3.0) を使用して背景画像を生成。
動画書き出しへの統合: 単色背景ではなく、シーンに応じた画像背景を合成する。
ユーザーレビュー事項
IMPORTANT

Gemini APIで画像生成を行うために、GeminiClient に画像生成用のメソッドを追加します。モデル名は imagen-3.0-generate-001 等を使用します。

変更内容
Modules/SceneModule
[NEW] 
SceneManager.swift
責務:
generateBackground(prompt: String) async throws -> URL: Geminiで画像を生成し、ローカルに保存してURLを返す。
importBackground(url: URL) throws -> URL: 既存画像をアセットフォルダにコピー。
背景リストの管理（IDとファイルパスの紐付け）。
Modules/AIInfra
[MODIFY] 
GeminiClient.swift
機能追加:
generateImage(prompt: String) async throws -> Data: Imagen 3.0 APIを呼び出すメソッドを追加。
Modules/TimeLineModule
[MODIFY] 
TimelineManager.swift
連携:
ScriptBlock に backgroundID (またはパス) を持たせる（既に定義はあるか確認、なければ追加）。
動画書き出し時に、ScriptBlock の背景情報を VideoScene に含めて VideoExportManager に渡す。
Modules/VideoModule
[MODIFY] 
VideoExportManager.swift
描画更新:
VideoScene 構造体に backgroundPath: URL? を追加。
drawAvatar (または drawScene) メソッドで、背景画像がある場合は CGContext.draw で画像を描画し、その上にアバターを描画するように変更。
現状の「感情による背景色変更」は、背景画像がない場合のフォールバックとして残す。
検証計画
自動テスト
今回はユーザービルドによる検証を主とします。
手動検証
ビルド & 実行: ユーザー側でアプリをビルド。
確認フロー:
UI（今回は実装範囲外だが、ロジック確認のためコンソール等で代用可か確認）から、またはコード上で SceneManager.generateBackground を呼び出すテストコードを一時的に追加。
timeline の特定のブロックに背景画像を指定。
Exportを実行。
生成された動画で、指定した時間の背景が画像になっていることを確認。