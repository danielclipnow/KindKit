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
    
    final class Group< Screen : IUIGroupScreen > : IUIGroupContainer, IUIContainerScreenable {
        
        public unowned var parent: IUIContainer? {
            didSet(oldValue) {
                guard self.parent !== oldValue else { return }
                if self.parent == nil || self.parent?.isPresented == true {
                    self.didChangeInsets()
                }
            }
        }
        public var shouldInteractive: Bool {
            return self.currentContainer?.shouldInteractive ?? false
        }
#if os(iOS)
        public var statusBarHidden: Bool {
            return self.currentContainer?.statusBarHidden ?? false
        }
        public var statusBarStyle: UIStatusBarStyle {
            return self.currentContainer?.statusBarStyle ?? .default
        }
        public var statusBarAnimation: UIStatusBarAnimation {
            return self.currentContainer?.statusBarAnimation ?? .fade
        }
        public var supportedOrientations: UIInterfaceOrientationMask {
            return self.currentContainer?.supportedOrientations ?? .portrait
        }
#endif
        public private(set) var isPresented: Bool
        public var view: IUIView {
            return self._view
        }
        public private(set) var screen: Screen
        public private(set) var barView: UI.View.GroupBar {
            set(value) {
                guard self._barView !== value else { return }
                self._barView.delegate = nil
                self._barView = value
                self._barView.delegate = self
                self._layout.barItem = UI.Layout.Item(self._barView)
            }
            get { return self._barView }
        }
        public var barSize: Float {
            get { return self._layout.barSize }
        }
        public private(set) var barVisibility: Float {
            set(value) { self._layout.barVisibility = value }
            get { return self._layout.barVisibility }
        }
        public private(set) var barHidden: Bool {
            set(value) { self._layout.barHidden = value }
            get { return self._layout.barHidden }
        }
        public var containers: [IUIGroupContentContainer] {
            return self._items.compactMap({ $0.container })
        }
        public var backwardContainer: IUIGroupContentContainer? {
            guard let current = self._current else { return nil }
            guard let index = self._items.firstIndex(where: { $0 === current }) else { return nil }
            return index > 0 ? self._items[index - 1].container : nil
        }
        public var currentContainer: IUIGroupContentContainer? {
            return self._current?.container
        }
        public var forwardContainer: IUIGroupContentContainer? {
            guard let current = self._current else { return nil }
            guard let index = self._items.firstIndex(where: { $0 === current }) else { return nil }
            return index < self._items.count - 1 ? self._items[index + 1].container : nil
        }
        public var animationVelocity: Float
        
        private var _barView: UI.View.GroupBar
        private var _layout: Layout
        private var _view: UI.View.Custom
        private var _items: [Item]
        private var _current: Item?
        
        public init(
            screen: Screen,
            containers: [IUIGroupContentContainer],
            current: IUIGroupContentContainer? = nil
        ) {
            self.isPresented = false
            self.screen = screen
#if os(macOS)
            self.animationVelocity = NSScreen.main!.animationVelocity
#elseif os(iOS)
            self.animationVelocity = UIScreen.main.animationVelocity
#endif
            self._barView = screen.groupBarView
            self._layout = .init(
                barItem: UI.Layout.Item(self._barView),
                barVisibility: screen.groupBarVisibility,
                barHidden: screen.groupBarHidden
            )
            self._view = UI.View.Custom(self._layout)
            self._items = containers.compactMap({ Item(container: $0) })
            if let current = current {
                if let index = self._items.firstIndex(where: { $0.container === current }) {
                    self._current = self._items[index]
                } else {
                    self._current = self._items.first
                }
            } else {
                self._current = self._items.first
            }
            self._init()
            UI.Container.BarController.shared.add(observer: self)
        }
        
        deinit {
            UI.Container.BarController.shared.remove(observer: self)
            self.screen.destroy()
        }
        
        public func insets(of container: IUIContainer, interactive: Bool) -> InsetFloat {
            let inheritedInsets = self.inheritedInsets(interactive: interactive)
            if self._items.contains(where: { $0.container === container }) == true {
                let bottom: Float
                if self.barHidden == false && UI.Container.BarController.shared.hidden(.group) == false {
                    let barSize = self.barSize
                    let barVisibility = self.barVisibility
                    if interactive == true {
                        bottom = barSize * barVisibility
                    } else {
                        bottom = barSize
                    }
                } else {
                    bottom = 0
                }
                return InsetFloat(
                    top: inheritedInsets.top,
                    left: inheritedInsets.left,
                    right: inheritedInsets.right,
                    bottom: inheritedInsets.bottom + bottom
                )
            }
            return inheritedInsets
        }
        
        public func didChangeInsets() {
            let inheritedInsets = self.inheritedInsets(interactive: true)
            if self.barHidden == false {
                self._barView.alpha = self.barVisibility
            } else {
                self._barView.alpha = 0
            }
            self._barView.safeArea(InsetFloat(top: 0, left: inheritedInsets.left, right: inheritedInsets.right, bottom: 0))
            self._layout.barOffset = inheritedInsets.bottom
            for item in self._items {
                item.container.didChangeInsets()
            }
        }
        
        public func activate() -> Bool {
            if self.screen.activate() == true {
                return true
            }
            if let current = self._current {
                return current.container.activate()
            }
            return false
        }
        
        public func didChangeAppearance() {
            self.screen.didChangeAppearance()
            for item in self._items {
                item.container.didChangeAppearance()
            }
        }
        
        public func prepareShow(interactive: Bool) {
            self.didChangeInsets()
            self.screen.prepareShow(interactive: interactive)
            self.currentContainer?.prepareShow(interactive: interactive)
        }
        
        public func finishShow(interactive: Bool) {
            self.isPresented = true
            self.screen.finishShow(interactive: interactive)
            self.currentContainer?.finishShow(interactive: interactive)
        }
        
        public func cancelShow(interactive: Bool) {
            self.screen.cancelShow(interactive: interactive)
            self.currentContainer?.cancelShow(interactive: interactive)
        }
        
        public func prepareHide(interactive: Bool) {
            self.screen.prepareHide(interactive: interactive)
            self.currentContainer?.prepareHide(interactive: interactive)
        }
        
        public func finishHide(interactive: Bool) {
            self.isPresented = false
            self.screen.finishHide(interactive: interactive)
            self.currentContainer?.finishHide(interactive: interactive)
        }
        
        public func cancelHide(interactive: Bool) {
            self.screen.cancelHide(interactive: interactive)
            self.currentContainer?.cancelHide(interactive: interactive)
        }
        
        public func updateBar(animated: Bool, completion: (() -> Void)?) {
            self.barView = self.screen.groupBarView
            self.barVisibility = self.screen.groupBarVisibility
            self.barHidden = self.screen.groupBarHidden
            self.didChangeInsets()
            completion?()
        }
        
        public func update(container: IUIGroupContentContainer, animated: Bool, completion: (() -> Void)?) {
            guard let item = self._items.first(where: { $0.container === container }) else {
                completion?()
                return
            }
            item.update()
            self._barView.itemViews(self._items.compactMap({ $0.barView }))
        }
        
        public func set(containers: [IUIGroupContentContainer], current: IUIGroupContentContainer?, animated: Bool, completion: (() -> Void)?) {
            let oldCurrent = self._current
            let removeItems = self._items.filter({ item in
                return containers.contains(where: { item.container === $0 && oldCurrent?.container !== $0 }) == false
            })
            for item in removeItems {
                item.container.parent = nil
            }
            let inheritedInsets = self.inheritedInsets(interactive: true)
            self._items = containers.compactMap({ Item(container: $0, insets: inheritedInsets) })
            for item in self._items {
                item.container.parent = self
            }
            self._barView.itemViews(self._items.compactMap({ $0.barView }))
            let newCurrent: Item?
            if current != nil {
                if let exist = self._items.first(where: { $0.container === current }) {
                    newCurrent = exist
                } else {
                    newCurrent = self._items.first
                }
            } else {
                newCurrent = self._items.first
            }
            if oldCurrent !== newCurrent {
                self._current = newCurrent
                self._set(current: oldCurrent, forward: newCurrent, animated: animated, completion: completion)
            } else {
                completion?()
            }
        }
        
        public func set(current: IUIGroupContentContainer, animated: Bool, completion: (() -> Void)?) {
            guard let newIndex = self._items.firstIndex(where: { $0.container === current }) else {
                completion?()
                return
            }
            let newCurrent = self._items[newIndex]
            if let oldCurrent = self._current {
                if oldCurrent !== newCurrent {
                    self._current = newCurrent
                    let oldIndex = self._items.firstIndex(where: { $0 === oldCurrent })!
                    if newIndex > oldIndex {
                        self._set(current: oldCurrent, forward: newCurrent, animated: animated, completion: completion)
                    } else {
                        self._set(current: oldCurrent, backward: newCurrent, animated: animated, completion: completion)
                    }
                } else {
                    completion?()
                }
            } else {
                self._set(current: nil, forward: newCurrent, animated: animated, completion: completion)
            }
        }
        
    }
    
}

extension UI.Container.Group : IGroupBarViewDelegate {
    
    func pressed(groupBar: UI.View.GroupBar, itemView: UI.View.GroupBar.Item) {
        guard let item = self._items.first(where: { $0.barView === itemView }) else { return }
        if self._current === item {
            _ = self.activate()
        } else {
            self.set(current: item.container, animated: true, completion: nil)
        }
    }
    
}

extension UI.Container.Group : IUIRootContentContainer {
}

extension UI.Container.Group : IUIStackContentContainer where Screen : IUIScreenStackable {
    
    public var stackBarView: UI.View.StackBar {
        return self.screen.stackBarView
    }
    
    public var stackBarVisibility: Float {
        return max(0, min(self.screen.stackBarVisibility, 1))
    }
    
    public var stackBarHidden: Bool {
        return self.screen.stackBarHidden
    }
    
}

extension UI.Container.Group : IUIDialogContentContainer where Screen : IUIScreenDialogable {
    
    public var dialogInset: InsetFloat {
        return self.screen.dialogInset
    }
    
    public var dialogWidth: DialogContentContainerSize {
        return self.screen.dialogWidth
    }
    
    public var dialogHeight: DialogContentContainerSize {
        return self.screen.dialogHeight
    }
    
    public var dialogAlignment: DialogContentContainerAlignment {
        return self.screen.dialogAlignment
    }
    
    public var dialogBackgroundView: (IUIView & IUIViewAlphable)? {
        return self.screen.dialogBackgroundView
    }
    
}

extension UI.Container.Group : IUIHamburgerContentContainer {
}

extension UI.Container.Group : IContainerBarControllerObserver {
    
    public func changed(_ barController: UI.Container.BarController) {
        self._layout.barVisibility = barController.visibility(.group)
    }
    
}

private extension UI.Container.Group {
    
    func _init() {
        self.screen.container = self
        self._barView.delegate = self
        for item in self._items {
            item.container.parent = self
        }
        self._barView.itemViews(self._items.compactMap({ $0.barView }))
        if let current = self._current {
            self._barView.selectedItemView(current.barView)
            self._layout.state = .idle(current: current.groupItem)
        }
        self.screen.setup()
    }
    
    func _set(
        current: Item?,
        forward: Item?,
        animated: Bool,
        completion: (() -> Void)?
    ) {
        if animated == true {
            if let current = current, let forward = forward {
                Animation.default.run(
                    duration: TimeInterval(self._view.contentSize.width / self.animationVelocity),
                    ease: Animation.Ease.QuadraticInOut(),
                    processing: { [weak self] progress in
                        guard let self = self else { return }
                        self._layout.state = .forward(current: current.groupItem, next: forward.groupItem, progress: progress)
                        if self.isPresented == true {
                            current.container.prepareHide(interactive: false)
                            forward.container.prepareShow(interactive: false)
                        }
                    },
                    completion: { [weak self] in
                        guard let self = self else { return }
                        self._barView.selectedItemView(forward.barView)
                        self._layout.state = .idle(current: forward.groupItem)
                        if self.isPresented == true {
                            current.container.finishHide(interactive: false)
                            forward.container.finishShow(interactive: false)
                        }
#if os(iOS)
                        self.setNeedUpdateOrientations()
                        self.setNeedUpdateStatusBar()
#endif
                        completion?()
                    }
                )
            } else if let forward = forward {
                if self.isPresented == true {
                    forward.container.prepareShow(interactive: false)
                }
                self._barView.selectedItemView(forward.barView)
                self._layout.state = .idle(current: forward.groupItem)
                if self.isPresented == true {
                    forward.container.finishShow(interactive: false)
                }
#if os(iOS)
                self.setNeedUpdateOrientations()
                self.setNeedUpdateStatusBar()
#endif
                completion?()
            } else if let current = current {
                if self.isPresented == true {
                    current.container.prepareHide(interactive: false)
                }
                self._barView.selectedItemView(nil)
                self._layout.state = .empty
                if self.isPresented == true {
                    current.container.finishHide(interactive: false)
                }
#if os(iOS)
                self.setNeedUpdateOrientations()
                self.setNeedUpdateStatusBar()
#endif
                completion?()
            } else {
                self._layout.state = .empty
#if os(iOS)
                self.setNeedUpdateOrientations()
                self.setNeedUpdateStatusBar()
#endif
                completion?()
            }
        } else if let current = current, let forward = forward {
            if self.isPresented == true {
                current.container.prepareHide(interactive: false)
                forward.container.prepareShow(interactive: false)
            }
            self._barView.selectedItemView(forward.barView)
            self._layout.state = .idle(current: forward.groupItem)
            if self.isPresented == true {
                current.container.finishHide(interactive: false)
                forward.container.finishShow(interactive: false)
            }
#if os(iOS)
            self.setNeedUpdateOrientations()
            self.setNeedUpdateStatusBar()
#endif
            completion?()
        } else if let forward = forward {
            if self.isPresented == true {
                forward.container.prepareShow(interactive: false)
            }
            self._barView.selectedItemView(forward.barView)
            self._layout.state = .idle(current: forward.groupItem)
            if self.isPresented == true {
                forward.container.finishShow(interactive: false)
            }
#if os(iOS)
            self.setNeedUpdateOrientations()
            self.setNeedUpdateStatusBar()
#endif
            completion?()
        } else if let current = current {
            if self.isPresented == true {
                current.container.prepareHide(interactive: false)
            }
            self._barView.selectedItemView(nil)
            self._layout.state = .empty
            if self.isPresented == true {
                current.container.finishHide(interactive: false)
            }
#if os(iOS)
            self.setNeedUpdateOrientations()
            self.setNeedUpdateStatusBar()
#endif
            completion?()
        } else {
            self._barView.selectedItemView(nil)
            self._layout.state = .empty
#if os(iOS)
            self.setNeedUpdateOrientations()
            self.setNeedUpdateStatusBar()
#endif
            completion?()
        }
    }
    
    func _set(
        current: Item?,
        backward: Item?,
        animated: Bool,
        completion: (() -> Void)?
    ) {
        if animated == true {
            if let current = current, let backward = backward {
                Animation.default.run(
                    duration: TimeInterval(self._view.contentSize.width / self.animationVelocity),
                    ease: Animation.Ease.QuadraticInOut(),
                    processing: { [weak self] progress in
                        guard let self = self else { return }
                        self._layout.state = .backward(current: current.groupItem, next: backward.groupItem, progress: progress)
                        if self.isPresented == true {
                            current.container.prepareHide(interactive: false)
                            backward.container.prepareShow(interactive: false)
                        }
                    },
                    completion: { [weak self] in
                        guard let self = self else { return }
                        self._barView.selectedItemView(backward.barView)
                        self._layout.state = .idle(current: backward.groupItem)
                        if self.isPresented == true {
                            current.container.finishHide(interactive: false)
                            backward.container.finishShow(interactive: false)
                        }
#if os(iOS)
                        self.setNeedUpdateOrientations()
                        self.setNeedUpdateStatusBar()
#endif
                        completion?()
                    }
                )
            } else if let backward = backward {
                if self.isPresented == true {
                    backward.container.prepareShow(interactive: false)
                }
                self._barView.selectedItemView(backward.barView)
                self._layout.state = .idle(current: backward.groupItem)
                if self.isPresented == true {
                    backward.container.finishShow(interactive: false)
                }
#if os(iOS)
                self.setNeedUpdateOrientations()
                self.setNeedUpdateStatusBar()
#endif
                completion?()
            } else if let current = current {
                if self.isPresented == true {
                    current.container.prepareHide(interactive: false)
                }
                self._barView.selectedItemView(nil)
                self._layout.state = .empty
                if self.isPresented == true {
                    current.container.finishHide(interactive: false)
                }
#if os(iOS)
                self.setNeedUpdateOrientations()
                self.setNeedUpdateStatusBar()
#endif
                completion?()
            } else {
                self._layout.state = .empty
#if os(iOS)
                self.setNeedUpdateOrientations()
                self.setNeedUpdateStatusBar()
#endif
                completion?()
            }
        } else if let current = current, let backward = backward {
            if self.isPresented == true {
                current.container.prepareHide(interactive: false)
                backward.container.prepareShow(interactive: false)
            }
            self._barView.selectedItemView(backward.barView)
            self._layout.state = .idle(current: backward.groupItem)
            if self.isPresented == true {
                current.container.finishHide(interactive: false)
                backward.container.finishShow(interactive: false)
            }
#if os(iOS)
            self.setNeedUpdateOrientations()
            self.setNeedUpdateStatusBar()
#endif
            completion?()
        } else if let backward = backward {
            if self.isPresented == true {
                backward.container.prepareShow(interactive: false)
            }
            self._barView.selectedItemView(nil)
            self._layout.state = .idle(current: backward.groupItem)
            if self.isPresented == true {
                backward.container.finishShow(interactive: false)
            }
#if os(iOS)
            self.setNeedUpdateOrientations()
            self.setNeedUpdateStatusBar()
#endif
            completion?()
        } else if let current = current {
            if self.isPresented == true {
                current.container.prepareHide(interactive: false)
            }
            self._barView.selectedItemView(nil)
            self._layout.state = .empty
            if self.isPresented == true {
                current.container.finishHide(interactive: false)
            }
#if os(iOS)
            self.setNeedUpdateOrientations()
            self.setNeedUpdateStatusBar()
#endif
            completion?()
        } else {
            self._barView.selectedItemView(nil)
            self._layout.state = .empty
#if os(iOS)
            self.setNeedUpdateOrientations()
            self.setNeedUpdateStatusBar()
#endif
            completion?()
        }
    }
    
}