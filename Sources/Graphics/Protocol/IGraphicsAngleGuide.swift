//
//  KindKit
//

import Foundation

public protocol IGraphicsAngleGuide : IGraphicsGuide {
    
    func guide(_ value: AngleFloat) -> AngleFloat?

}