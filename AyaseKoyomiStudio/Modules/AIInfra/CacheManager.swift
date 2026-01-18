import Foundation

final class CacheManager {
    static let shared = CacheManager()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let audioCacheDirectory: URL
    private let imageCacheDirectory: URL
    
    private init() {
        // Library/Caches/AyaseKoyomiStudio
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let root = caches.appendingPathComponent("AyaseKoyomiStudio")
        self.cacheDirectory = root
        self.audioCacheDirectory = root.appendingPathComponent("Audio")
        self.imageCacheDirectory = root.appendingPathComponent("Images")
        
        createDirectories()
    }
    
    private func createDirectories() {
        try? fileManager.createDirectory(at: audioCacheDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: imageCacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Audio Cache
    
    func getAudio(key: String) -> Data? {
        let fileURL = audioCacheDirectory.appendingPathComponent(key + ".mp3")
        return try? Data(contentsOf: fileURL)
    }
    
    func saveAudio(_ data: Data, key: String) {
        let fileURL = audioCacheDirectory.appendingPathComponent(key + ".mp3")
        try? data.write(to: fileURL)
    }
    
    // MARK: - Image Cache
    
    func getImage(key: String) -> Data? {
        let fileURL = imageCacheDirectory.appendingPathComponent(key + ".png")
        return try? Data(contentsOf: fileURL)
    }
    
    func saveImage(_ data: Data, key: String) {
        let fileURL = imageCacheDirectory.appendingPathComponent(key + ".png")
        try? data.write(to: fileURL)
    }
    
    // MARK: - Maintenance
    
    func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        createDirectories()
    }
}
