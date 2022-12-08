//
//  KindKit
//

import Foundation
import PhotosUI

public extension Permission {
    
    final class PhotoLibrary : IPermission {
        
        public let access: Access
        public var status: Permission.Status {
            switch self._rawStatus() {
            case .notDetermined: return .notDetermined
            case .denied, .restricted: return .denied
            case .authorized, .limited: return .authorized
            default: return .denied
            }
        }
        
        private var _observer: Observer< IPermissionObserver >
        private var _resignSource: Any?
        private var _resignState: Permission.Status?
#if os(iOS)
        private var _becomeActiveObserver: NSObjectProtocol?
        private var _resignActiveObserver: NSObjectProtocol?
#endif
        
        public init(
            _ access: Access
        ) {
            self.access = access
            
            self._observer = Observer()
            
#if os(iOS)
            self._becomeActiveObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: OperationQueue.main,
                using: { [weak self] in self?._didBecomeActive($0) }
            )
            self._resignActiveObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.willResignActiveNotification,
                object: nil,
                queue: OperationQueue.main,
                using: { [weak self] in self?._didResignActive($0) }
            )
#endif
        }
        
        deinit {
#if os(iOS)
            if let observer = self._becomeActiveObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            if let observer = self._resignActiveObserver {
                NotificationCenter.default.removeObserver(observer)
            }
#endif
        }
        
        public func add(observer: IPermissionObserver, priority: ObserverPriority) {
            self._observer.add(observer, priority: priority)
        }
        
        public func remove(observer: IPermissionObserver) {
            self._observer.remove(observer)
        }
        
        public func request(source: Any) {
            switch self._rawStatus() {
            case .notDetermined:
                self._willRequest(source: source)
                if #available(iOS 14, *) {
                    PHPhotoLibrary.requestAuthorization(for: self.access.level, handler: { [weak self] _ in
                        DispatchQueue.main.async(execute: {
                            self?._didRequest(source: source)
                        })
                    })
                } else {
                    PHPhotoLibrary.requestAuthorization({ [weak self] _ in
                        DispatchQueue.main.async(execute: {
                            self?._didRequest(source: source)
                        })
                    })
                }
            case .denied:
#if os(iOS)
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                if UIApplication.shared.canOpenURL(url) == true {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    self._resignSource = source
                    self._didRedirectToSettings(source: source)
                }
#endif
            default:
                break
            }
        }
        
    }
    
}

#if os(iOS)

private extension Permission.PhotoLibrary {
    
    func _didBecomeActive(_ notification: Notification) {
        guard let resignState = self._resignState else { return }
        if resignState != self.status {
            self._didRequest(source: self._resignSource)
        }
        self._resignSource = nil
        self._resignState = nil
    }
    
    func _didResignActive(_ notification: Notification) {
        switch self.status {
        case .authorized: self._resignState = .authorized
        case .denied: self._resignState = .denied
        default: self._resignState = nil
        }
    }
    
}

#endif

private extension Permission.PhotoLibrary {
    
    func _rawStatus() -> PHAuthorizationStatus {
        if #available(iOS 14, *) {
            return PHPhotoLibrary.authorizationStatus(for: self.access.level)
        } else {
            return PHPhotoLibrary.authorizationStatus()
        }
    }
    
    func _didRedirectToSettings(source: Any) {
        self._observer.notify({ $0.didRedirectToSettings(self, source: source) })
    }
    
    func _willRequest(source: Any?) {
        self._observer.notify({ $0.willRequest(self, source: source) })
    }
    
    func _didRequest(source: Any?) {
#if os(iOS)
        UIApplication.shared.registerForRemoteNotifications()
#endif
        self._observer.notify({ $0.didRequest(self, source: source) })
    }
    
}
