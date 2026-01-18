実装計画 - Lv.4 ビデオレンダラー & 字幕書き出し
本計画は、機能仕様書 Version 3 (4.5節) で定義されている「ビデオレンダラー (Lv.4)」機能、特に動画および字幕のエクスポート機能の実装について記述します。

目標
動画書き出しモジュールを以下の機能で実装します：

アバター、音声、背景を合成し、最終的な動画ファイル (.mp4) を生成する。
日本語のオリジナル字幕 (.srt) と、Gemini APIを用いて翻訳した英語字幕 (.srt) を生成する。
ユーザーレビュー事項
NOTE

現在の VideoExportManager は、アバター描画にシンプルなCoreGraphicsを使用しています。今回はコードベースの現状に従いこの「フラットデザイン」スタイルを維持しますが、将来的に AvatarModule に置き換え可能な構造にします。

IMPORTANT

SRT生成と翻訳を処理するために、新しく SubtitleManager (または拡張機能) を追加します。

変更内容
Modules/VideoModule
[MODIFY] 
VideoExportManager.swift
機能更新:
exportVideo を拡張し、字幕生成フローとの連携を考慮（またはヘルパー呼び出し）。
SceneModule が利用可能な場合、背景画像の描画に対応できるように drawAvatar を調整（現状は色のフォールバックを維持）。
補足: 仕様書では字幕生成は ExportModule の一部とされていますが、コードの見通しを良くするためクラスを分離します。
[NEW] 
SubtitleManager.swift
新規クラス: SubtitleManager
責務:
generateSRT(blocks: [ScriptBlock]) -> String: スクリプトブロックからSRT形式のテキストを生成。
translateSRT(srtContent: String) async throws -> String: Gemini API (AIInfra) を使用して英語に翻訳。
saveSRT(content: String, to url: URL): ファイル保存。
Modules/TimeLineModule
[MODIFY] 
TimelineManager.swift
統合:
compileAndExport() メソッド内:
動画書き出し完了後、SubtitleManager を呼び出して .ja.srt を生成。
同マネージャーを使用して .en.srt (翻訳版) を生成。
動画ファイルと同じ場所に字幕ファイルを保存。
Modules/AIInfra (必要な場合)
[MODIFY] 
GeminiClient.swift
翻訳用のメソッドが存在しない場合、追加または generateContent を再利用できるか確認。
検証計画
自動テスト
UIやAVFoundationに強く依存するため、今回はユーザーによるビルド確認を主とします。
手動検証
ビルド & 実行: ユーザー側でアプリをビルド。
確認フロー:
スクリプトブロックをいくつか追加する。
「Export」（動画書き出し）を実行する。
指定した保存先に Video.mp4, Video.ja.srt, Video.en.srt が生成されているか確認。
動画を再生し、映像と音声のズレがないか確認。
SRTファイルを開き、タイムスタンプと翻訳内容が正しいか確認。