import Foundation
@preconcurrency import AVFoundation
import CoreImage
import AppKit

// ★★★ クラス全体を MainActor にしてUIスレッドで管理 ★★★
@MainActor
final class VideoExportManager: NSObject {
    
    static let shared = VideoExportManager()
    private override init() { super.init() }
    
    private let videoSize = CGSize(width: 1080, height: 1080)
    private let frameRate: Int32 = 30
    
    enum ExportError: LocalizedError {
        case failedToCreateAssetWriter, failedToCreateAudioFile, failedToReadAudioSamples, trackNotFound
        case exportFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .failedToCreateAssetWriter: return "AssetWriter作成失敗"
            case .failedToCreateAudioFile: return "音声ファイル読込失敗"
            case .failedToReadAudioSamples: return "音声サンプル読込失敗"
            case .trackNotFound: return "トラック不明"
            case .exportFailed(let msg): return "書き出し失敗: \(msg)"
            }
        }
    }
    
    // ★★★ nonisolated でメインスレッドから切り離して実行 ★★★
    nonisolated func exportVideo(audioData: Data) async throws -> URL {
        print("🎥 Export: 開始")
        
        let tempDir = FileManager.default.temporaryDirectory
        let uuid = UUID().uuidString
        let audioTempURL = tempDir.appendingPathComponent("\(uuid).mp3")
        let videoOutputURL = tempDir.appendingPathComponent("\(uuid).mp4")
        
        try? FileManager.default.removeItem(at: audioTempURL)
        try? FileManager.default.removeItem(at: videoOutputURL)
        try audioData.write(to: audioTempURL)
        
        let audioFile = try AVAudioFile(forReading: audioTempURL)
        let audioFormat = audioFile.processingFormat
        let audioFrameCount = AVAudioFrameCount(audioFile.length)
        let sampleRate = audioFormat.sampleRate
        let duration = Double(audioFrameCount) / sampleRate
        let totalVideoFrames = Int(duration * Double(frameRate))
        
        guard let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount) else {
            throw ExportError.failedToReadAudioSamples
        }
        try audioFile.read(into: audioBuffer)
        
        guard let assetWriter = try? AVAssetWriter(outputURL: videoOutputURL, fileType: .mp4) else {
            throw ExportError.failedToCreateAssetWriter
        }
        
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(videoSize.width),
            AVVideoHeightKey: Int(videoSize.height)
        ])
        videoInput.expectsMediaDataInRealTime = false
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: Int(videoSize.width),
                kCVPixelBufferHeightKey as String: Int(videoSize.height)
            ]
        )
        
        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: audioFormat.channelCount,
            AVEncoderBitRateKey: 128000
        ])
        audioInput.expectsMediaDataInRealTime = false
        
        if assetWriter.canAdd(videoInput) { assetWriter.add(videoInput) }
        if assetWriter.canAdd(audioInput) { assetWriter.add(audioInput) }
        
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)
        
        let audioAsset = AVURLAsset(url: audioTempURL)
        let tracks = try await audioAsset.loadTracks(withMediaType: .audio)
        guard let audioTrack = tracks.first else { throw ExportError.trackNotFound }
        
        let assetReader = try AVAssetReader(asset: audioAsset)
        let readerOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ])
        
        if assetReader.canAdd(readerOutput) { assetReader.add(readerOutput) }
        assetReader.startReading()
        
        let targetVideoSize = self.videoSize
        let targetFrameRate = self.frameRate
        
        // ★★★ コンパイラチェックを回避するための安全な箱 ★★★
        struct VideoContext: @unchecked Sendable {
            let input: AVAssetWriterInput
            let adaptor: AVAssetWriterInputPixelBufferAdaptor
            let buffer: AVAudioPCMBuffer
        }
        
        struct AudioContext: @unchecked Sendable {
            let input: AVAssetWriterInput
            let output: AVAssetReaderTrackOutput
        }
        
        let videoCtx = VideoContext(input: videoInput, adaptor: pixelBufferAdaptor, buffer: audioBuffer)
        let audioCtx = AudioContext(input: audioInput, output: readerOutput)
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            
            // Task 1: 映像
            group.addTask {
                await withCheckedContinuation { continuation in
                    let videoQueue = DispatchQueue(label: "videoQueue")
                    var frameIndex = 0
                    
                    // ★★★ 修正ポイント: ここで videoCtx (箱) を使って呼び出す ★★★
                    // 中身 (input) をローカル変数にしてから呼び出すと、その変数がキャプチャされてWarningになるため
                    videoCtx.input.requestMediaDataWhenReady(on: videoQueue) {
                        
                        // ★★★ クロージャの「中」で箱を開ける ★★★
                        // ここなら実行コンテキスト内なので安全にアクセスできる
                        let input = videoCtx.input
                        let adaptor = videoCtx.adaptor
                        let buffer = videoCtx.buffer
                        
                        while input.isReadyForMoreMediaData && frameIndex < totalVideoFrames {
                            let time = CMTime(value: CMTimeValue(frameIndex), timescale: targetFrameRate)
                            let seconds = Double(frameIndex) / Double(targetFrameRate)
                            
                            let volume = getVolume(at: seconds, audioBuffer: buffer, sampleRate: sampleRate)
                            if let pixelBuffer = createPixelBuffer(videoSize: targetVideoSize, volume: volume) {
                                adaptor.append(pixelBuffer, withPresentationTime: time)
                            }
                            frameIndex += 1
                        }
                        
                        if frameIndex >= totalVideoFrames {
                            input.markAsFinished()
                            continuation.resume()
                        }
                    }
                }
                print("🎥 映像完了")
            }
            
            // Task 2: 音声
            group.addTask {
                await withCheckedContinuation { continuation in
                    let audioQueue = DispatchQueue(label: "audioQueue")
                    
                    // ★★★ 修正ポイント: 音声側も同様に箱 (audioCtx) を使う ★★★
                    audioCtx.input.requestMediaDataWhenReady(on: audioQueue) {
                        let input = audioCtx.input
                        let output = audioCtx.output
                        
                        while input.isReadyForMoreMediaData {
                            if let sampleBuffer = output.copyNextSampleBuffer() {
                                input.append(sampleBuffer)
                            } else {
                                input.markAsFinished()
                                continuation.resume()
                                break
                            }
                        }
                    }
                }
                print("🔊 音声完了")
            }
            
            try await group.waitForAll()
        }
        
        await assetWriter.finishWriting()
        
        if assetWriter.status == .completed {
            try? FileManager.default.removeItem(at: audioTempURL)
            print("✅ 保存成功: \(videoOutputURL)")
            return videoOutputURL
        } else {
            throw ExportError.exportFailed(assetWriter.error?.localizedDescription ?? "Unknown")
        }
    }
}

// MARK: - Helper Functions (クラス外)

private func getVolume(at time: Double, audioBuffer: AVAudioPCMBuffer, sampleRate: Double) -> Float {
    guard let data = audioBuffer.floatChannelData?[0] else { return 0 }
    let index = Int(time * sampleRate)
    let window = Int(sampleRate * 0.05)
    let start = max(0, index - window/2)
    let end = min(Int(audioBuffer.frameLength)-1, index + window/2)
    guard start < end else { return 0 }
    
    var sum: Float = 0
    for i in start...end { sum += abs(data[i]) }
    return min(1.0, (sum / Float(end - start + 1)) * 5.0)
}

private func createPixelBuffer(videoSize: CGSize, volume: Float) -> CVPixelBuffer? {
    var pb: CVPixelBuffer?
    CVPixelBufferCreate(kCFAllocatorDefault, Int(videoSize.width), Int(videoSize.height), kCVPixelFormatType_32ARGB, nil, &pb)
    guard let buffer = pb else { return nil }
    
    CVPixelBufferLockBaseAddress(buffer, [])
    defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
    
    let context = CGContext(
        data: CVPixelBufferGetBaseAddress(buffer),
        width: Int(videoSize.width), height: Int(videoSize.height),
        bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
    )
    
    if let ctx = context {
        drawAvatar(videoSize: videoSize, context: ctx, volume: volume)
    }
    return buffer
}

private func drawAvatar(videoSize: CGSize, context: CGContext, volume: Float) {
    let w = videoSize.width, h = videoSize.height
    let cx = w/2, cy = h/2
    
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: w, height: h))
    
    context.setFillColor(CGColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 1))
    context.fillEllipse(in: CGRect(x: cx-300, y: cy-300, width: 600, height: 600))
    
    context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
    context.fillEllipse(in: CGRect(x: cx-120, y: cy+30, width: 40, height: 60))
    context.fillEllipse(in: CGRect(x: cx+80, y: cy+30, width: 40, height: 60))
    
    let mH = 10 + (70 * CGFloat(volume))
    context.setFillColor(CGColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1))
    context.fillEllipse(in: CGRect(x: cx-50, y: cy-100-mH/2, width: 100, height: mH))
}
