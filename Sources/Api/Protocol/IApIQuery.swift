//
//  KindKitApi
//

import Foundation
import KindKitCore

public protocol IApiQuery : ICancellable {

    var provider: IApiProvider { get }
    var createAt: Date { get }

    func redirect(request: URLRequest) -> URLRequest?

}
