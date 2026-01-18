実装計画 - 最終機能群 (保存・解像度・アセット)
残りの要件である、プロジェクト保存機能、解像度変更オプション、キャラクター画像アセット対応を実装します。

目標
プロジェクト保存: 編集中のスクリプトと設定を .koyomi ファイル (JSON) として保存・読み込み可能にする。
解像度変更: 1920x1080 (16:9) と 1080x1080 (1:1) を切り替え可能にする。
アセット対応: 背景と同様に、アバターの顔画像をインポートして使用可能にする（SF Symbols/シェイプからの脱却）。
実装内容
1. プロジェクト保存 (.koyomi)
[MODIFY] 
TimelineManager.swift
Codable対応: ScriptBlock は既にCodableなはず（確認）。
ProjectData構造体: 保存するデータをまとめる。
struct ProjectData: Codable {
    let blocks: [ScriptBlock]
    let resolution: VideoResolution // 後述
    // APIキーはセキュリティのため保存しない
}
メソッド追加:
saveProject(videoURL: URL)
loadProject(url: URL)
UI: TimelineView に「保存」「開く」ボタンを追加（Toolbar配置などを検討）。
2. 解像度オプション
[NEW] 
VideoResolution.swift
Enum定義: case landscape (1920x1080), case square (1080x1080)
[MODIFY] 
VideoExportManager.swift
exportVideo メソッドの引数に resolution: VideoResolution を追加。
現在は 1920x1080 固定になっている箇所を動的に変更。
[MODIFY] 
TimelineManager.swift
@Published var resolution: VideoResolution = .landscape を追加。
[MODIFY] 
TimelineView.swift
フッターまたはヘッダーに解像度選択Pickerを追加。
3. キャラクター画像アセット
[MODIFY] 
SceneManager.swift
背景同様、キャラクター画像（顔ベース）の管理機能を追加（今回は簡易的に）。
@Published var avatarFaceImageURL: URL?
[MODIFY] 
AvatarView.swift
SceneManager を参照し、avatarFaceImageURL があれば画像を表示し、なければ Circle (黄色) を描画。
[MODIFY] 
VideoExportManager.swift
drawAvatar メソッドで画像描画に対応。
検証計画
保存/読込: スクリプトを書き、保存してアプリ再起動後に読み込めるか。
解像度: 1:1 に設定して書き出し、正方形の動画ができるか。
アセット: 任意の画像を顔として設定し、プレビューと書き出し動画に反映されるか。