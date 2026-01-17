import SwiftUI

// MARK: - 1行分のビュー (変更なし)
struct ScriptRowView: View {
    @Binding var block: ScriptBlock
    var onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Menu {
                ForEach(AvatarEmotion.allCases) { emotion in
                    Button { block.emotion = emotion } label: { Text(emotion.rawValue) }
                }
            } label: {
                Text(block.emotion.rawValue.prefix(1))
                    .font(.title2)
                    .frame(width: 30, height: 30)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            .menuStyle(.borderlessButton)
            
            TextField("セリフを入力...", text: $block.text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body)
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            Button(action: onDelete) {
                Image(systemName: "trash").foregroundColor(.gray)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - メイン画面
struct TimelineView: View {
    @StateObject private var manager = TimelineManager()
    
    // ★修正: AppStorage(保存)をやめ、State(一時保持)に戻しました
    @State private var apiKey: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // リストエリア
                List {
                    ForEach($manager.blocks) { $block in
                        ScriptRowView(block: $block, onDelete: {
                            if let index = manager.blocks.firstIndex(where: { $0.id == block.id }) {
                                withAnimation { _ = manager.blocks.remove(at: index) }
                            }
                        })
                    }
                    .onMove(perform: manager.moveBlock)
                }
                .listStyle(.inset)
                
                // コントロールエリア (Footer)
                VStack(spacing: 12) {
                    
                    // APIキー入力 (毎回入力必須)
                    SecureField("Gemini APIキーを入力", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: apiKey) { _, newValue in
                            manager.apiKey = newValue
                        }
                    
                    HStack(spacing: 16) {
                        // 行追加ボタン
                        Button(action: { withAnimation { manager.addBlock() } }) {
                            Label("行を追加", systemImage: "plus")
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        // 書き出しボタン
                        Button(action: {
                            Task { await manager.compileAndExport() }
                        }) {
                            if manager.isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .frame(width: 100)
                            } else {
                                Label("動画を書き出す", systemImage: "film")
                                    .font(.headline)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 20)
                                    .background(apiKey.isEmpty ? Color.gray : Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(apiKey.isEmpty || manager.isProcessing)
                    }
                    
                    // エラー表示
                    if let error = manager.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor))
                .shadow(radius: 1)
            }
            .navigationTitle("脚本エディタ 📝")
        }
    }
}

#Preview {
    TimelineView()
}
