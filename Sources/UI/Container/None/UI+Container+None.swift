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
    
    final class None : IUIContainer, IUIContainerParentable {
        
        public weak var parent: IUIContainer? {
            didSet {
                guard self.parent !== oldValue else { return }
                if let parent = self.parent {
                    if parent.isPresented == true {
                        self.refreshParentInset()
                    }
                } else {
                    self.refreshParentInset()
                }
            }
        }
        public var shouldInteractive: Bool {
            return false
        }
#if os(iOS)
        public var statusBar: UIStatusBarStyle {
            return .default
        }
        public var statusBarAnimation: UIStatusBarAnimation {
            return .fade
        }
        public var statusBarHidden: Bool {
            return false
        }
        public var supportedOrientations: UIInterfaceOrientationMask {
            return .all
        }
#endif
        public private(set) var isPresented: Bool
        public var view: IUIView {
            return self._view
        }
        
        private var _view: UI.View.Rect
        private var _parentInset: UI.Container.AccumulateInset = .zero {
            didSet {
                guard self._parentInset != oldValue else { return }
                self.refreshContentInset()
            }
        }
        
        public init(
            _ color: UI.Color = .clear
        ) {
            self.isPresented = false
            self._view = UI.View.Rect()
                .fill(color)
        }
        
        public func apply(contentInset: UI.Container.AccumulateInset) {
        }
        
        public func parentInset(for container: IUIContainer) -> UI.Container.AccumulateInset {
            return self.parentInset()
        }
        
        public func contentInset() -> UI.Container.AccumulateInset {
            return .zero
        }
        
        public func refreshParentInset() {
            self._parentInset = self.parentInset()
        }
        
        public func activate() -> Bool {
            return false
        }
        
        public func didChangeAppearance() {
        }
        
        public func prepareShow(interactive: Bool) {
        }
        
        public func finishShow(interactive: Bool) {
            self.isPresented = true
        }
        
        public func cancelShow(interactive: Bool) {
        }
        
        public func prepareHide(interactive: Bool) {
        }
        
        public func finishHide(interactive: Bool) {
            self.isPresented = false
        }
        
        public func cancelHide(interactive: Bool) {
        }
        
    }
    
}

extension UI.Container.None : IUIRootContentContainer {
}

extension UI.Container.None : IUIGroupContentContainer {
    
    public var groupItem: UI.View.GroupBar.Item {
        let rect = UI.View.Rect()
            .fill(.red)
            .cornerRadius(.auto)
        return .init()
            .content(rect)
    }
    
}

extension UI.Container.None : IUIPageContentContainer {
    
    public var pageItem: UI.View.PageBar.Item {
        let rect = UI.View.Rect()
            .fill(.red)
            .cornerRadius(.auto)
        return .init()
            .content(rect)
    }
    
}

extension UI.Container.None : IUIStackContentContainer {
    
    public var stackBar: UI.View.StackBar { .init().size(50) }
    public var stackBarVisibility: Double { 1 }
    public var stackBarHidden: Bool { false }
    
}

extension UI.Container.None : IUIBookContentContainer {
    
    public var bookIdentifier: Any { self }
    
}

extension UI.Container.None : IUIHamburgerContentContainer {
}

extension UI.Container.None : IHamburgerMenuContainer {
    
    public var hamburgerSize: Double { 120 }
    public var hamburgerLimit: Double { 120 }
    
}

extension UI.Container.None : IUIModalContentContainer {
    
    public var modalColor: UI.Color { .white }
    public var modalSheet: UI.Modal.Presentation.Sheet? { nil }
    
    public func modalPressedOutside() {
    }
    
}

extension UI.Container.None : IUIDialogContentContainer {
    
    public var dialogInset: Inset { .zero }
    public var dialogWidth: DialogContentContainerSize { .fill(before: 24, after: 24) }
    public var dialogHeight: DialogContentContainerSize { .fill(before: 24, after: 24) }
    public var dialogAlignment: DialogContentContainerAlignment { .center }
    public var dialogBackground: (IUIView & IUIViewAlphable)? { nil }
    
}

extension UI.Container.None : IUIPushContentContainer {
    
    public var pushPlacement: UI.Push.Placement { .top }
    public var pushOptions: UI.Push.Options { [] }
    public var pushDuration: TimeInterval? { 5 }
    
}
