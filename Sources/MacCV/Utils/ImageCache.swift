import AppKit

final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()
    private var cache = NSCache<NSString, NSImage>()

    private init() {
        cache.countLimit = 200
    }

    func image(for path: String) -> NSImage? {
        if let cached = cache.object(forKey: path as NSString) {
            return cached
        }
        let url = Database.shared.imageURL(for: path)
        guard let image = NSImage(contentsOf: url) else { return nil }
        cache.setObject(image, forKey: path as NSString)
        return image
    }

    func thumbnail(for path: String, maxSize: NSSize = NSSize(width: 120, height: 90)) -> NSImage? {
        guard let image = self.image(for: path) else { return nil }
        return image.resized(to: maxSize)
    }

    func clear() {
        cache.removeAllObjects()
    }
}

extension NSImage {
    func resized(to targetSize: NSSize) -> NSImage {
        let newImage = NSImage(size: targetSize)
        newImage.lockFocus()
        let dstRect = NSRect(origin: .zero, size: targetSize)
        let srcRect = NSRect(origin: .zero, size: size)
        draw(in: dstRect, from: srcRect, operation: .copy, fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
}
