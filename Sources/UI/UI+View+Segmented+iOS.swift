//
//  KindKit
//

#if os(iOS)

import UIKit

extension UI.View.Segmented {
    
    struct Reusable : IUIReusable {
        
        typealias Owner = UI.View.Segmented
        typealias Content = KKSegmentedView

        static var reuseIdentificator: String {
            return "UI.View.Segmented"
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

final class KKSegmentedView : UISegmentedControl {
    
    weak var kkDelegate: KKSegmentedViewDelegate?
    
    var items: [UI.View.Segmented.Item] = [] {
        willSet {
            self.removeAllSegments()
        }
        didSet {
            for item in self.items {
                switch item {
                case .string(let string): self.insertSegment(withTitle: string, at: self.numberOfSegments, animated: false)
                case .image(let image): self.insertSegment(with: image.native, at: self.numberOfSegments, animated: false)
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.clipsToBounds = true
        
        self.addTarget(self, action: #selector(self._changed(_:)), for: .valueChanged)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension KKSegmentedView {
    
    func update(view: UI.View.Segmented) {
        self.update(items: view.items)
        self.update(selected: view.selected)
        self.update(locked: view.isLocked)
        self.update(color: view.color)
        self.update(alpha: view.alpha)
        self.kkDelegate = view
    }
    
    func update(items: [UI.View.Segmented.Item]) {
        self.items = items
    }
    
    func update(selected: UI.View.Segmented.Item?) {
        if let selected = selected {
            if let index = self.items.firstIndex(of: selected) {
                self._update(selected: index)
            } else {
                self._update(selected: Self.noSegment)
            }
        } else {
            self._update(selected: Self.noSegment)
        }
    }
    
    func update(color: UI.Color?) {
        self.backgroundColor = color?.native
    }
    
    func update(alpha: Float) {
        self.alpha = CGFloat(alpha)
    }
    
    func update(locked: Bool) {
        self.isEnabled = locked == false
    }
    
    func cleanup() {
        self.kkDelegate = nil
    }
    
}

private extension KKSegmentedView {
    
    func _update(selected: Int) {
        if self.superview == nil {
            UIView.performWithoutAnimation({
                self.selectedSegmentIndex = selected
                self.layoutIfNeeded()
            })
        } else {
            self.selectedSegmentIndex = selected
        }
    }
    
    @objc
    func _changed(_ sender: Any) {
        self.kkDelegate?.selected(self, index: self.selectedSegmentIndex)
    }
    
}

#endif
