//
//  KindKitRemoteImageView
//

import Foundation
import KindKitCore
import KindKitMath
import KindKitView

public extension RemoteImage.Filter {
    
    final class Grayscale : IRemoteImageFilter {

        public var name: String {
            return "grayscale"
        }
        
        public init() {
        }
        
        public func apply(_ image: Image) -> Image? {
            return image.grayscale
        }
        
    }
    
}
