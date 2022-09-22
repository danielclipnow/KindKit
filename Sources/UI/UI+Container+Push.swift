//
//  KindKit
//

import Foundation
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

public extension UI.Container {
    
    final class Push : IUIPushContainer {
        
        public unowned var parent: IUIContainer? {
            didSet(oldValue) {
                guard self.parent !== oldValue else { return }
                if self.parent == nil || self.parent?.isPresented == true {
                    self.didChangeInsets()
                }
            }
        }
        public var shouldInteractive: Bool {
            return self.contentContainer?.shouldInteractive ?? false
        }
#if os(iOS)
        public var statusBarHidden: Bool {
            guard let current = self._current else {
                return self.contentContainer?.statusBarHidden ?? false
            }
            return current.container.statusBarHidden
        }
        public var statusBarStyle: UIStatusBarStyle {
            guard let current = self._current else {
                return self.contentContainer?.statusBarStyle ?? .default
            }
            return current.container.statusBarStyle
        }
        public var statusBarAnimation: UIStatusBarAnimation {
            guard let current = self._current else {
                return self.contentContainer?.statusBarAnimation ?? .fade
            }
            return current.container.statusBarAnimation
        }
        public var supportedOrientations: UIInterfaceOrientationMask {
            guard let current = self._current else {
                return self.contentContainer?.supportedOrientations ?? .all
            }
            return current.container.supportedOrientations
        }
#endif
        public private(set) var isPresented: Bool
        public var view: IUIView {
            return self._view
        }
        public var additionalInset: InsetFloat {
            set(value) { self._layout.additionalInset = value }
            get { return self._layout.additionalInset }
        }
        public var contentContainer: (IUIContainer & IUIContainerParentable)? {
            didSet(oldValue) {
                if let contentContainer = self.contentContainer {
                    if self.isPresented == true {
                        contentContainer.prepareHide(interactive: false)
                        contentContainer.finishHide(interactive: false)
                    }
                    contentContainer.parent = nil
                }
                self._layout.contentItem = self.contentContainer.flatMap({ UI.Layout.Item($0.view) })
                if let contentContainer = self.contentContainer {
                    contentContainer.parent = self
                    if self.isPresented == true {
                        contentContainer.prepareHide(interactive: false)
                        contentContainer.finishHide(interactive: false)
                    }
                }
            }
        }
        public var containers: [IUIPushContentContainer] {
            return self._items.compactMap({ return $0.container })
        }
        public var previousContainer: IUIPushContentContainer? {
            return self._previous?.container
        }
        public var currentContainer: IUIPushContentContainer? {
            return self._current?.container
        }
        public var animationVelocity: Float
#if os(iOS)
        public var interactiveLimit: Float
#endif
        
        private var _layout: Layout
        private var _view: UI.View.Custom
#if os(iOS)
        private var _interactiveGesture = UI.Gesture.Pan().enabled(false)
        private var _interactiveBeginLocation: PointFloat?
#endif
        private var _items: [Item]
        private var _previous: Item?
        private var _current: Item? {
            didSet {
#if os(iOS)
                self._interactiveGesture.isEnabled = self._current != nil
#endif
            }
        }
        private var _timer: Timer?
        
        public init(
            additionalInset: InsetFloat = InsetFloat(horizontal: 8, vertical: 8),
            contentContainer: (IUIContainer & IUIContainerParentable)? = nil
        ) {
            self.isPresented = false
#if os(macOS)
            self.animationVelocity = 500
#elseif os(iOS)
            self.animationVelocity = 500
            self.interactiveLimit = 20
#endif
            self.contentContainer = contentContainer
            self._layout = .init(
                additionalInset: additionalInset,
                containerInset: .zero,
                contentItem: contentContainer.flatMap({ UI.Layout.Item($0.view) }),
                state: .empty
            )
            self._view = UI.View.Custom(self._layout)
#if os(iOS)
            self._view.gestures([ self._interactiveGesture ])
#endif
            self._items = []
            self._init()
        }
        
        deinit {
            self._timerReset()
        }
        
        public func insets(of container: IUIContainer, interactive: Bool) -> InsetFloat {
            return self.inheritedInsets(interactive: interactive)
        }
        
        public func didChangeInsets() {
            self._layout.containerInset = self.inheritedInsets(interactive: true)
            self.contentContainer?.didChangeInsets()
            for container in self.containers {
                container.didChangeInsets()
            }
        }
        
        public func activate() -> Bool {
            if let current = self._current {
                if current.container.activate() == true {
                    return true
                }
            }
            if let contentContainer = self.contentContainer {
                return contentContainer.activate()
            }
            return false
        }
        
        public func didChangeAppearance() {
            for container in self.containers {
                container.didChangeAppearance()
            }
            if let contentContainer = self.contentContainer {
                contentContainer.didChangeAppearance()
            }
        }
        
        public func prepareShow(interactive: Bool) {
            self.contentContainer?.prepareShow(interactive: interactive)
            self.currentContainer?.prepareShow(interactive: interactive)
        }
        
        public func finishShow(interactive: Bool) {
            self.isPresented = true
            self.contentContainer?.finishShow(interactive: interactive)
            self.currentContainer?.finishShow(interactive: interactive)
        }
        
        public func cancelShow(interactive: Bool) {
            self.contentContainer?.cancelShow(interactive: interactive)
            self.currentContainer?.cancelShow(interactive: interactive)
        }
        
        public func prepareHide(interactive: Bool) {
            self.contentContainer?.prepareHide(interactive: interactive)
            self.currentContainer?.prepareHide(interactive: interactive)
        }
        
        public func finishHide(interactive: Bool) {
            self.isPresented = false
            self.contentContainer?.finishHide(interactive: interactive)
            self.currentContainer?.finishHide(interactive: interactive)
        }
        
        public func cancelHide(interactive: Bool) {
            self.contentContainer?.cancelHide(interactive: interactive)
            self.currentContainer?.cancelHide(interactive: interactive)
        }
        
        public func present(container: IUIPushContentContainer, animated: Bool, completion: (() -> Void)?) {
            container.parent = self
            let item = Item(container: container, available: self._view.bounds.size)
            self._items.append(item)
            if self._current == nil {
                self._present(push: item, animated: animated, completion: completion)
            } else {
                completion?()
            }
        }
        
        public func dismiss(container: IUIPushContentContainer, animated: Bool, completion: (() -> Void)?) {
            guard let index = self._items.firstIndex(where: { $0.container === container }) else {
                completion?()
                return
            }
            let item = self._items[index]
            if self._current === item {
                self._items.remove(at: index)
                self._previous = self._items.first
                self._dismiss(current: item, previous: self._previous, animated: animated, completion: {
                    container.parent = nil
                    completion?()
                })
            } else {
                container.parent = nil
                self._items.remove(at: index)
                completion?()
            }
        }
        
    }
    
}

extension UI.Container.Push : IUIRootContentContainer {
}

private extension UI.Container.Push {
    
    func _init() {
#if os(iOS)
        self._interactiveGesture.onShouldBeRequiredToFailBy({ [unowned self] _, gesture -> Bool in
            guard let contentContainer = self.contentContainer else { return true }
            guard let view = gesture.view else { return false }
            return contentContainer.view.native.isChild(of: view, recursive: true)
        }).onShouldBegin({ [unowned self] _ in
            guard let current = self._current else { return false }
            guard current.container.shouldInteractive == true else { return false }
            guard self._interactiveGesture.contains(in: current.container.view) == true else { return false }
            return true
        }).onBegin({ [unowned self] _ in
            self._beginInteractiveGesture()
        }) .onChange({ [unowned self] _ in
            self._changeInteractiveGesture()
        }).onCancel({ [unowned self] _ in
            self._endInteractiveGesture(true)
        }).onEnd({ [unowned self] _ in
            self._endInteractiveGesture(false)
        })
#endif
        self.contentContainer?.parent = self
    }
    
    func _timerReset() {
        self._timer?.stop()
        self._timer = nil
    }
    
    func _timerTriggered() {
        self._timerReset()
        if let currentItem = self._current {
            if let index = self._items.firstIndex(where: { $0 === currentItem }) {
                self._items.remove(at: index)
            }
            self._previous = self._items.first
            self._dismiss(current: currentItem, previous: self._previous, animated: true, completion: {
                currentItem.container.parent = nil
            })
        }
    }
    
    func _present(current: Item?, next: Item, animated: Bool, completion: (() -> Void)?) {
        if let current = current {
            self._dismiss(push: current, animated: animated, completion: { [weak self] in
                guard let self = self else { return }
                self._present(push: next, animated: animated, completion: completion)
            })
        } else {
            self._present(push: next, animated: animated, completion: completion)
        }
    }
    
    func _present(push: Item, animated: Bool, completion: (() -> Void)?) {
        self._current = push
        push.container.prepareShow(interactive: false)
        if animated == true {
            Animation.default.run(
                duration: TimeInterval(push.size.height / self.animationVelocity),
                ease: Animation.Ease.QuadraticInOut(),
                processing: { [weak self] progress in
                    guard let self = self else { return }
                    self._layout.state = .present(push: push, progress: progress)
                    self._layout.updateIfNeeded()
                },
                completion: { [weak self] in
                    guard let self = self else { return }
                    self._didPresent(push: push)
                    push.container.finishShow(interactive: false)
                    self._layout.state = .idle(push: push)
#if os(iOS)
                    self.setNeedUpdateOrientations()
                    self.setNeedUpdateStatusBar()
#endif
                    completion?()
                }
            )
        } else {
            self._didPresent(push: push)
            push.container.finishShow(interactive: false)
            self._layout.state = .idle(push: push)
#if os(iOS)
            self.setNeedUpdateOrientations()
            self.setNeedUpdateStatusBar()
#endif
        }
    }
    
    func _didPresent(push: Item) {
        if let duration = push.container.pushDuration {
            let timer = Timer(interval: duration, delay: 0, repeating: 0)
            timer.onFinished(self._timerTriggered)
            timer.start()
            self._timer = timer
        }
    }
    
    func _dismiss(current: Item, previous: Item?, animated: Bool, completion: (() -> Void)?) {
        self._dismiss(push: current, animated: animated, completion: { [weak self] in
            guard let self = self else { return }
            self._current = previous
            if let previous = previous {
                self._present(push: previous, animated: animated, completion: completion)
            } else {
                completion?()
            }
        })
    }
    
    func _dismiss(push: Item, animated: Bool, completion: (() -> Void)?) {
        push.container.prepareHide(interactive: false)
        if animated == true {
            Animation.default.run(
                duration: TimeInterval(push.size.height / self.animationVelocity),
                ease: Animation.Ease.QuadraticInOut(),
                processing: { [weak self] progress in
                    guard let self = self else { return }
                    self._layout.state = .dismiss(push: push, progress: progress)
                    self._layout.updateIfNeeded()
                },
                completion: { [weak self] in
                    guard let self = self else { return }
                    push.container.finishHide(interactive: false)
                    self._layout.state = .empty
#if os(iOS)
                    self.setNeedUpdateOrientations()
                    self.setNeedUpdateStatusBar()
#endif
                    completion?()
                }
            )
        } else {
            push.container.finishHide(interactive: false)
            self._layout.state = .empty
#if os(iOS)
            self.setNeedUpdateOrientations()
            self.setNeedUpdateStatusBar()
#endif
        }
    }
    
}

#if os(iOS)

private extension UI.Container.Push {
    
    func _beginInteractiveGesture() {
        guard let current = self._current else { return }
        self._interactiveBeginLocation = self._interactiveGesture.location(in: self._view)
        self._timer?.pause()
        current.container.prepareHide(interactive: true)
    }
    
    func _changeInteractiveGesture() {
        guard let beginLocation = self._interactiveBeginLocation, let current = self._current else { return }
        let currentLocation = self._interactiveGesture.location(in: self._view)
        let deltaLocation = currentLocation.y - beginLocation.y
        if deltaLocation < 0 {
            let height = self._layout.height(item: current)
            let progress = Percent(-deltaLocation / height)
            self._layout.state = .dismiss(push: current, progress: progress)
        } else if deltaLocation > 0 {
            let height = self._layout.height(item: current)
            let progress = Percent(deltaLocation / pow(height, 1.5))
            self._layout.state = .present(push: current, progress: .one + progress)
        } else {
            self._layout.state = .idle(push: current)
        }
    }
    
    func _endInteractiveGesture(_ canceled: Bool) {
        guard let beginLocation = self._interactiveBeginLocation, let current = self._current else { return }
        let currentLocation = self._interactiveGesture.location(in: self._view)
        let deltaLocation = currentLocation.y - beginLocation.y
        if deltaLocation < -self.interactiveLimit {
            let height = self._layout.height(item: current)
            Animation.default.run(
                duration: TimeInterval(height / self.animationVelocity),
                elapsed: TimeInterval(-deltaLocation / self.animationVelocity),
                processing: { [weak self] progress in
                    guard let self = self else { return }
                    self._layout.state = .dismiss(push: current, progress: progress)
                    self._layout.updateIfNeeded()
                },
                completion: { [weak self] in
                    guard let self = self else { return }
                    self._finishInteractiveAnimation()
                }
            )
        } else if deltaLocation > 0 {
            let height = self._layout.height(item: current)
            let baseProgress = Percent(deltaLocation / pow(height, 1.5))
            Animation.default.run(
                duration: TimeInterval((height * baseProgress.value) / self.animationVelocity),
                processing: { [weak self] progress in
                    guard let self = self else { return }
                    self._layout.state = .present(push: current, progress: .one + (baseProgress - (baseProgress * progress)))
                    self._layout.updateIfNeeded()
                },
                completion: { [weak self] in
                    guard let self = self else { return }
                    self._cancelInteractiveAnimation()
                }
            )
        } else {
            self._layout.state = .idle(push: current)
            self._cancelInteractiveAnimation()
        }
    }
    
    func _finishInteractiveAnimation() {
        self._timerReset()
        self._interactiveBeginLocation = nil
        if let current = self._current {
            current.container.finishHide(interactive: true)
            current.container.parent = nil
            if let index = self._items.firstIndex(where: { $0 === current }) {
                self._items.remove(at: index)
            }
            self._previous = self._items.first
            if let previous = self._previous {
                self._present(push: previous, animated: true, completion: nil)
            } else {
                self._current = nil
                self._layout.state = .empty
                self.setNeedUpdateOrientations()
                self.setNeedUpdateStatusBar()
            }
        } else {
            self._current = nil
            self._layout.state = .empty
            self.setNeedUpdateOrientations()
            self.setNeedUpdateStatusBar()
        }
    }
    
    func _cancelInteractiveAnimation() {
        self._interactiveBeginLocation = nil
        self._timer?.resume()
        if let current = self._current {
            current.container.cancelHide(interactive: true)
            self._layout.state = .idle(push: current)
        } else {
            self._layout.state = .empty
        }
        self.setNeedUpdateOrientations()
        self.setNeedUpdateStatusBar()
    }
    
}

#endif