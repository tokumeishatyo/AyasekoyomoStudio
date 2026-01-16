ビルド成功、おめでとうございます！
AIを活用したプロダクト開発における**「Xcodeプロジェクトの立ち上げから、AIライブラリ導入、署名設定までの標準手順」**をまとめました。

次回以降の新規プロジェクトでも、この手順書があれば迷わず環境構築ができます。ドキュメントとして保存してご利用ください。

---

# AIプロダクト開発 環境構築手順書 (macOS/iOS)

**対象:** Xcode を使用した Gemini API (Google Generative AI SDK) 利用アプリ
**更新日:** 2026/01/16

## 1. プロジェクトの新規作成

1. Xcodeを起動し、**Create New Project** を選択。
2. プラットフォームを選択（macOS または iOS）。
3. **App** を選択し、Next をクリック。
4. 以下の基本設定を入力:
* **Product Name:** (プロジェクト名)
* **Team:** (個人のApple IDチーム、または組織チームを選択)
* ※ `None` にすると署名エラーになるため必ず選択すること。


* **Organization Identifier:** `com.yourname` など
* **Interface:** `SwiftUI`
* **Language:** `Swift`
* **Storage:** `None` (Core Data等は必要に応じて後で追加)
* **Include Tests:** オフ (初期構築をシンプルにするため)



## 2. ターゲット設定と署名 (Signing)

**重要:** Appleの仕様により、開発中のアプリでも署名が必要です。

1. 左ナビゲータで **プロジェクト名(青いアイコン)** を選択。
2. **TARGETS** から対象アプリを選択。
3. **Signing & Capabilities** タブを開く。
4. **Team** が正しく選択されているか確認。
* エラーが出ている場合（赤字）:
* **[Sign In...]** ボタンが出ている場合は押し、Apple IDパスワードを入力して再認証する。
* **Automatically manage signing** のチェックを一度外し、再度入れる（リフレッシュ）。




5. **General** タブへ移動。
6. **Minimum Deployments** を設定。
* Google Generative AI SDKの動作要件を満たす設定にする。
* **macOS:** `14.0` 以上
* **iOS:** `15.0` 以上



## 3. AIライブラリの導入 (Google Generative AI SDK)

1. メニューバー **File** > **Add Package Dependencies...** を選択。
2. 検索バーに公式SDKのURLを入力:
`https://github.com/google/generative-ai-swift`
3. **Add Package** をクリック。
4. `Package Product` 選択画面で、**GoogleGenerativeAI** にチェックが入っていることを確認し、**Add Package** を確定。

## 4. モジュール構成の作成 (アーキテクチャ)

AIアプリは「UI」「AI通信」「ロジック」が複雑になりがちなため、初期段階でフォルダ分けを行う。

Project Navigatorで右クリック > **New Group** で以下の構成を作成:

```text
ProjectName
├── App            (App.swiftエントリーポイント)
├── UI             (View, Components)
├── Modules        (ロジック層)
│   ├── AIInfra      (API通信・リポジトリ)
│   ├── VoiceModule  (音声処理・TTS)
│   ├── AvatarModule (画像処理・表情管理)
│   └── TimelineModule (シナリオ進行管理)
└── Resources      (Assets.xcassets, Configファイル)

```

## 5. 初回ビルド確認

1. キーボードの **Command + B** を押下。
2. **"Build Succeeded"** と表示されれば環境構築完了。

---

## 6. (参考) APIキーの管理ベストプラクティス

APIキーをコード内に直接書くことはセキュリティリスクがあるため、以下のいずれかの方法を推奨。

* **方法A (簡易):** `.gitignore` に登録した `Secrets.swift` ファイルを作り、そこに定数として定義する。
* **方法B (推奨):** `.xcconfig` ファイルを作成して環境変数として管理し、`Info.plist` 経由で読み込む。


## 7．ネットワーク接続を許可する
Xcodeの左側のナビゲータで、一番上の青いアイコン AyaseKoyomiStudio をクリックします。

右側の画面で TARGETS の AyaseKoyomiStudio を選択します。

上部タブの Signing & Capabilities をクリックします。

画面の中に App Sandbox という項目があるはずです。

その中の Network というセクションにある：

Outgoing Connections (Client) のチェックボックスを ON (☑️) にしてください。

(※もし App Sandbox という項目自体が見当たらない場合) 左上の + Capability ボタンを押し、「Sandbox」と検索して App Sandbox を追加してから、上記のチェックを入れてください。