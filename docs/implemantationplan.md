実装計画 - 自動瞬き機能 (Lv.1)
ドキュメント 
docs/残作業.txt
 に基づき、自動瞬き機能 (Automatic Blinking) を実装します。これにより、キャラクターの自然さを向上させます。

目標
EyesStateの管理: AvatarManager に EyesState (Open, Closed, Smile) を追加。
自動瞬きタイマー: 3.0〜5.0秒ごとにランダムで瞬きを実行するロジックを実装。
描画への反映: VideoExportManager およびアバター表示UIに目の状態を反映させる。
変更内容
Modules/AvatarModule
[MODIFY] 
AvatarManager.swift
Enum追加: EyesState (open, closed, smile)
プロパティ追加: @Published var eyesState: EyesState = .open
タイマーロジック:
startBlinking(): 瞬きループを開始。
scheduleNextBlink(): 3.0〜5.0秒後のランダムなタイミングで blink() をスケジュール。
blink(): close → 0.1秒待機 → open の一連の動作を実行。
連携: 音声再生開始時に瞬きロジックも有効化（または常時有効化するか検討、Lv.1ではアプリ起動中ずっと瞬きして良さそうだが、一旦 init で開始）。
Modules/VideoModule
[MODIFY] 
VideoExportManager.swift
描画更新:
drawAvatar メソッド内で、渡された eyesState に基づいて目の描画を変更。
注意: 動画書き出し時はリアルタイムのタイマーではなく、疑似的なランダム性または固定パターンで瞬きを入れる必要がある（あるいは書き出しフローでは瞬きを省略するか、仕様を確認）。
仕様再考: 動画書き出し (Lv.4) と リアルタイムプレビュー (Lv.1) は異なる。
Lv.1: アプリ画面上のアバターが瞬きする。
Lv.4: 動画に瞬きが含まれるか？ -> 機能仕様書 4.2 には「自動瞬き」とあるが、これは主にリアルタイム動作を指すことが多い。ただし動画にも反映されるべき。
動画への反映方針: TimelineManager.compileAndExport 内で VideoScene を作る際、ブロックの長さに関わらず一定間隔で「瞬きシーン」を挿入するのは複雑になりすぎる。
簡易方針: 今回はまず 「アプリ起動中のリアルタイム瞬き (AvatarManager)」 を優先実装する。VideoExportへの反映は、もし時間が許せば「ランダムに瞬きフレームを混ぜる」ロジックを検討するが、まずはUI上の動きを実装する。
検証計画
手動検証
アプリを起動し、アバターが3〜5秒おきにパチパチと瞬きすることを確認する。
喋っている間も瞬きすることを確認する。