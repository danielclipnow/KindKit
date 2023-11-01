//
//  KindKit
//

import AVFoundation

public extension Permission {
    
    final class Audio : Permission.Base {
        
        public override var status: Permission.Status {
            switch AVCaptureDevice.kk_authorizationStatus {
            case .notDetermined: return .notDetermined
            case .denied, .restricted: return .denied
            case .authorized: return .authorized
            default: return .denied
            }
        }
        
        public override func request(source: Any) {
            switch AVCaptureDevice.kk_authorizationStatus {
            case .notDetermined:
                self.willRequest(source: source)
                AVCaptureDevice.requestAccess(for: .audio, completionHandler: { [weak self] granted in
                    DispatchQueue.main.async(execute: {
                        self?.didRequest(source: source)
                    })
                })
            case .denied:
                self.redirectToSettings(source: source)
            default:
                break
            }
        }
        
    }
    
}

public extension IPermission where Self : Permission.Audio {
    
    static func audio() -> Self {
        return .init()
    }
    
}

fileprivate extension AVCaptureDevice {
    
    @inline(__always)
    static var kk_authorizationStatus: AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .audio)
    }
    
}
