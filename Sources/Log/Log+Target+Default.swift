//
//  KindKitLog
//

import Foundation

public extension Log.Target {
    
    final class Default : ILogTarget {
        
        public var enabled: Bool
        
        public init(
            enabled: Bool = true
        ) {
            self.enabled = enabled
        }
        
        public func log(level: Log.Level, category: String, message: String) {
            guard self.enabled == true else { return }
            print("[\(category)]: \(message)")
        }
        
    }
    
}
