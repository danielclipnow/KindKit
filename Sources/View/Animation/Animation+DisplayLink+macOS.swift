//
//  KindKitView
//

#if os(OSX)

import AppKit
import KindKitCore

public extension Animation {
    
    class DisplayLink {
        
        unowned var delegate: IAnimationQueueDelegate?
        
        var isRunning: Bool {
            return CVDisplayLinkIsRunning(self._displayLink)
        }
        
        fileprivate var _displayLink: CVDisplayLink!
        fileprivate var _prevTime: CVTimeStamp!
        
        init?() {
            guard CVDisplayLinkCreateWithActiveCGDisplays(&self._displayLink) == kCVReturnSuccess else {
                return nil
            }
            guard CVDisplayLinkSetOutputCallback(self._displayLink!, AnimationDisplayLinkCallback, Unmanaged.passUnretained(self).toOpaque()) == kCVReturnSuccess else {
                return nil
            }
            guard CVDisplayLinkSetCurrentCGDisplay(self._displayLink!, CGMainDisplayID()) == kCVReturnSuccess else {
                return nil
            }
            guard CVDisplayLinkGetCurrentTime(self._displayLink!, &self._prevTime) == kCVReturnSuccess else {
                return nil
            }
        }
        
        deinit {
            self.stop()
        }
        
        func start() {
            CVDisplayLinkStart(self._displayLink)
        }
        
        func stop() {
            CVDisplayLinkStop(self._displayLink)
        }
        
    }
    
}

fileprivate func AnimationDisplayLinkCallback(_ displayLink: CVDisplayLink, _ nowTime: UnsafePointer< CVTimeStamp >, _ outputTime: UnsafePointer< CVTimeStamp >, _ flagsIn: CVOptionFlags, _ flagsOut: UnsafeMutablePointer< CVOptionFlags >, _ context: UnsafeMutableRawPointer?) -> CVReturn {
    guard let context = context else { return kCVReturnSuccess }
    let displayLink = Unmanaged< Animation.DisplayLink >.fromOpaque(context).takeRetainedValue()
    let delta = Float(outputTime.pointee.videoTime - displayLink._prevTime.videoTime) / Float(outputTime.pointee.videoTimeScale)
    displayLink._prevTime = outputTime.pointee
    displayLink.delegate?.update(delta)
    return kCVReturnSuccess
}

#endif
