import Foundation
import UIKit

final class ImageCache {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private let queue = DispatchQueue(
        label: "com.testApp.imagecache.queue",
        attributes: .concurrent
    )

    func setImage(_ image: UIImage, forKey key: String) {
        queue.async(flags: .barrier) {
            self.cache.setObject(image, forKey: key as NSString)
        }
    }

    func image(forKey key: String) -> UIImage? {
        queue.sync {
            return cache.object(forKey: key as NSString)
        }
    }
}
