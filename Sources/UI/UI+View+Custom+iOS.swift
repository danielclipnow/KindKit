//
//  KindKit
//

#if os(iOS)

import UIKit

extension UI.View.Custom {
    
    struct Reusable : IUIReusable {
        
        typealias Owner = UI.View.Custom
        typealias Content = KKCustomView

        static var reuseIdentificator: String {
            return "UI.View.Custom"
        }
        
        static func createReuse(owner: Owner) -> Content {
            return Content(frame: .zero)
        }
        
        static func configureReuse(owner: Owner, content: Content) {
            content.update(view: owner)
        }
        
        static func cleanupReuse(content: Content) {
            content.cleanup()
        }
        
    }
    
}

final class KKCustomView : UIView {
        
    weak var kkDelegate: KKCustomViewDelegate?
    var contentSize: SizeFloat {
        return self._layoutManager.size
    }
    override var frame: CGRect {
        set {
            let oldValue = super.frame
            if oldValue != newValue {
                super.frame = newValue
                if oldValue.size != newValue.size {
                    if self.window != nil {
                        self._layoutManager.invalidate()
                    }
                }
            }
        }
        get { super.frame }
    }

    private var _layoutManager: UI.Layout.Manager!
    private var _gestures: [IUIGesture] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.clipsToBounds = true
        
        self._layoutManager = UI.Layout.Manager(contentView: self, delegate: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func willMove(toSuperview superview: UIView?) {
        super.willMove(toSuperview: superview)
        
        if superview == nil {
            self._layoutManager.clear()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let bounds = RectFloat(self.bounds)
        self._layoutManager.layout(bounds: bounds)
        self._layoutManager.visible(bounds: bounds)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if hitView === self {
            if self.kkDelegate?.hasHit(self, point: .init(point)) == false {
                return nil
            }
        }
        return hitView
    }
    
    override func touchesBegan(_ touches: Set< UITouch >, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if self.kkDelegate?.shouldHighlighting(self) == true {
            self.kkDelegate?.set(self, highlighted: true)
        }
    }
    
    override func touchesEnded(_ touches: Set< UITouch >, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if self.kkDelegate?.shouldHighlighting(self) == true {
            self.kkDelegate?.set(self, highlighted: false)
        }
    }
    
    override func touchesCancelled(_ touches: Set< UITouch >, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        if self.kkDelegate?.shouldHighlighting(self) == true {
            self.kkDelegate?.set(self, highlighted: false)
        }
    }

}

extension KKCustomView {
    
    func update(view: UI.View.Custom) {
        self.update(gestures: view.gestures)
        self.update(content: view.content)
        self.update(color: view.color)
        self.update(alpha: view.alpha)
        self.update(locked: view.isLocked)
        self.kkDelegate = view
    }
    
    func update(content: IUILayout?) {
        self._layoutManager.layout = content
        self.setNeedsLayout()
    }
    
    func update(gestures: [IUIGesture]) {
        for gesture in self._gestures {
            self.removeGestureRecognizer(gesture.native)
        }
        self._gestures = gestures
        for gesture in self._gestures {
            self.addGestureRecognizer(gesture.native)
        }
    }
    
    func update(color: UI.Color?) {
        self.backgroundColor = color?.native
    }
    
    func update(alpha: Float) {
        self.alpha = CGFloat(alpha)
    }
    
    func update(locked: Bool) {
        self.isUserInteractionEnabled = locked == false
    }
    
    func cleanup() {
        self._layoutManager.layout = nil
        for gesture in self._gestures {
            self.removeGestureRecognizer(gesture.native)
        }
        self._gestures.removeAll()
        self.kkDelegate = nil
    }
    
    func add(gesture: IUIGesture) {
        if self._gestures.contains(where: { $0 === gesture }) == false {
            self._gestures.append(gesture)
        }
        self.addGestureRecognizer(gesture.native)
    }
    
    func remove(gesture: IUIGesture) {
        if let index = self._gestures.firstIndex(where: { $0 === gesture }) {
            self._gestures.remove(at: index)
        }
        self.removeGestureRecognizer(gesture.native)
    }
    
}

extension KKCustomView : IUILayoutDelegate {
    
    func setNeedUpdate(_ appearedLayout: IUILayout) -> Bool {
        self.setNeedsLayout()
        return true
    }
    
    func updateIfNeeded(_ appearedLayout: IUILayout) {
        self.layoutIfNeeded()
    }
    
}

#endif
