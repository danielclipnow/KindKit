//
//  KindKit
//

import AVFoundation

public extension CameraSession.Recorder {
    
    final class Movie : ICameraSessionRecorder {
        
        public weak var session: CameraSession?
#if os(iOS)
        public var deviceOrientation: CameraSession.Orientation? {
            didSet {
                guard self.deviceOrientation != oldValue else { return }
                if let context = self._context {
                    let orientation = self.resolveOrientation(shouldRotateToDevice: context.config.rotateToDeviceOrientation)
                    self.apply(videoOrientation: orientation)
                }
            }
        }
        public var interfaceOrientation: CameraSession.Orientation? {
            didSet {
                guard self.interfaceOrientation != oldValue else { return }
                if let context = self._context {
                    let orientation = self.resolveOrientation(shouldRotateToDevice: context.config.rotateToDeviceOrientation)
                    self.apply(videoOrientation: orientation)
                }
            }
        }
#endif
        public var output: AVCaptureOutput {
            return self._output
        }
        public var isRecording: Bool {
            return self._delegate != nil && self._context != nil
        }
        public let storage: Storage.FileSystem
        public let supportedCodecs: [Codec]

        private let _output = AVCaptureMovieFileOutput()
        private var _delegate: Delegate?
        private var _context: Context?
        private var _restorePreset: CameraSession.Device.Video.Preset?
        private var _restoreFlashMode: CameraSession.Device.Video.Torch?

        public init(
            storage: Storage.FileSystem
        ) {
            self.storage = storage
#if os(macOS)
            self.supportedCodecs = [ .hevc, .h264 ]
#elseif os(iOS)
            self.supportedCodecs = self._output.availableVideoCodecTypes.compactMap({ .init($0) })
#endif
            self._output.movieFragmentInterval = .invalid
        }
        
        public func attach(session: CameraSession) {
            guard self.isAttached == false else { return }
            self.session = session
        }
        
        public func detach() {
            guard self.isAttached == true else { return }
            self.session = nil
        }
        
        public func cancel() {
            guard self.isRecording == true else { return }
            self._delegate = nil
            self._context = nil
        }
        
    }
    
}

public extension CameraSession.Recorder.Movie {
    
    var recordedDuration: CMTime {
        return self._output.recordedDuration
    }
    
    var recordedFileSize: Int64 {
        return self._output.recordedFileSize
    }
    
    func start(
        config: Config = .init(),
        onSuccess: @escaping (TemporaryFile) -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        self._start(.init(
            config: config,
            onSuccess: onSuccess,
            onFailure: onFailure
        ))
    }
    
    func stop() {
        guard self.isRecording == true else {
            return
        }
        self._output.stopRecording()
    }
    
}

private extension CameraSession.Recorder.Movie {
    
    func _start(
        _ context: Context
    ) {
        guard self.isRecording == false else {
            return
        }
        if let session = self.session {
            if let preset = context.config.preset {
                self._restorePreset = preset
                session.configure(
                    videoPreset: preset,
                    completion: { [weak self] in
                        guard let self = self else { return }
                        self._start(context, session)
                    }
                )
            } else {
                self._start(context, session)
            }
        } else {
            DispatchQueue.main.async(execute: {
                context.onFailure(.notConneted)
            })
        }
    }
    
    func _start(
        _ context: Context,
        _ session: CameraSession
    ) {
        let delegate = Delegate(recorder: self)
        self._delegate = delegate
        self._context = context
        
#if os(iOS)
        let orientation = self.resolveOrientation(shouldRotateToDevice: context.config.rotateToDeviceOrientation)
        self.apply(videoOrientation: orientation)
#endif
        
        if let connection = self.videoConnection {
            if let codec = context.config.codec {
                if self.supportedCodecs.contains(codec) == true {
                    self._output.setOutputSettings([ AVVideoCodecKey : codec.raw ], for: connection)
                } else {
#if DEBUG
                    fatalError("Not supported codec type \(codec)")
#endif
                }
            }
#if os(iOS)
            if let stabilizationMode = context.config.stabilizationMode {
                connection.preferredVideoStabilizationMode = stabilizationMode.raw
            }
            if context.config.rotateToDeviceOrientation == true {
                self._output.setRecordsVideoOrientationAndMirroringChangesAsMetadataTrack(true, for: connection)
            }
#endif
        }
        self._output.maxRecordedDuration = context.config.maxDuration
        self._output.maxRecordedFileSize = context.config.maxFileSize
        self._output.startRecording(
            to: self.storage.url(name: UUID().uuidString, extension: "mp4"),
            recordingDelegate: delegate
        )
    }
    
    func _restore(_ completion: @escaping () -> Void) {
        guard let session = self.session else { return }
        session.configure(
            videoPreset: self._restorePreset,
            configureVideoDevice: {
                if let flashMode = self._restoreFlashMode {
                    if $0.isTorchSupported() == true {
                        $0.set(torch: flashMode)
                    }
                }
            },
            completion: completion
        )
    }
    
}

extension CameraSession.Recorder.Movie {
    
    func started() {
        guard let device = self.session?.activeVideoDevice else { return }
        guard let context = self._context else { return }
        if context.config.flashMode != nil {
            device.configuration({
                if let flashMode = context.config.flashMode {
                    if $0.isTorchSupported() == true {
                        self._restoreFlashMode = $0.torch()
                        $0.set(torch: flashMode)
                    }
                }
            })
        }
    }
    
    func finish(_ url: TemporaryFile) {
        guard let context = self._context else {
            return
        }
        self._delegate = nil
        self._context = nil
        self._restore({
            context.onSuccess(url)
        })
    }
    
    func finish(_ error: Swift.Error) {
        guard let context = self._context else {
            return
        }
        self._delegate = nil
        self._context = nil
        self._restore({
            context.onFailure(.internal(error))
        })
    }

}
