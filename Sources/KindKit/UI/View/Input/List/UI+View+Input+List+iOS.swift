//
//  KindKit
//

#if os(iOS)

import UIKit

extension UI.View.Input.List {
    
    struct Reusable : IUIReusable {
        
        typealias Owner = UI.View.Input.List
        typealias Content = KKInputListView

        static var reuseIdentificator: String {
            return "UI.View.Input.List"
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

final class KKInputListView : UITextField {
    
    weak var kkDelegate: KKInputListViewDelegate?
    let kkAccessoryView: KKAccessoryView
    var kkItems: [IInputListItem] = [] {
        didSet {
            self.kkPicker.reloadAllComponents()
            self._applyText()
        }
    }
    var kkSelected: IInputListItem? {
        didSet {
            guard self.kkSelected !== oldValue else { return }
            let animated = self.isFirstResponder
            if let selected = self.kkSelected {
                if let index = self.kkItems.firstIndex(where: { $0 === selected }) {
                    self.kkPicker.selectRow(index, inComponent: 0, animated: animated)
                } else {
                    self.kkPicker.selectRow(0, inComponent: 0, animated: animated)
                }
            } else {
                self.kkPicker.selectRow(0, inComponent: 0, animated: animated)
            }
            self._applyText()
        }
    }
    var kkTextInset: UIEdgeInsets = .zero {
        didSet {
            guard self.kkTextInset != oldValue else { return }
            self.setNeedsLayout()
        }
    }
    var kkPlaceholderInset: UIEdgeInsets? {
        didSet {
            guard self.kkPlaceholderInset != oldValue else { return }
            self.setNeedsLayout()
        }
    }

    private var kkPicker: UIPickerView
    
    override init(frame: CGRect) {
        self.kkAccessoryView = .init(
            frame: .init(
                x: 0,
                y: 0,
                width: UIScreen.main.bounds.width,
                height: 0
            )
        )
        self.kkPicker = UIPickerView()

        super.init(frame: frame)
        
        self.kkAccessoryView.kkInput = self
        self.inputAccessoryView = self.kkAccessoryView
        self.clipsToBounds = true
        self.delegate = self
        
        self.kkPicker.dataSource = self
        self.kkPicker.delegate = self
        self.inputView = self.kkPicker
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func reloadInputViews() {
        do {
            let width = UIScreen.main.bounds.width
            let height = self.kkAccessoryView.kkHeight
            self.kkAccessoryView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        }
        super.reloadInputViews()
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: self.kkTextInset)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: self.kkTextInset)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        let inset = self.kkPlaceholderInset ?? self.kkTextInset
        return bounds.inset(by: inset)
    }

}

extension KKInputListView {
    
    final class KKAccessoryView : UIInputView {
        
        weak var kkInput: KKInputListView?
        var kkToolbarView: UIView? {
            willSet {
                guard self.kkToolbarView !== newValue else { return }
                self.kkToolbarView?.removeFromSuperview()
            }
            didSet {
                guard self.kkToolbarView !== oldValue else { return }
                if let view = self.kkToolbarView {
                    self.addSubview(view)
                }
                self.kkInput?.reloadInputViews()
            }
        }
        var kkContentViews: [UIView] {
            var views: [UIView] = []
            if let view = self.kkToolbarView {
                views.append(view)
            }
            return views
        }
        var kkHeight: CGFloat {
            var result: CGFloat = 0
            for subview in self.kkContentViews {
                result += subview.frame.height
            }
            return result
        }
        
        init(frame: CGRect) {
            super.init(frame: frame, inputViewStyle: .keyboard)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            let bounds = self.bounds
            var offset: CGFloat = 0
            for subview in self.kkContentViews {
                let height = subview.frame.height
                subview.frame = CGRect(
                    x: bounds.origin.x,
                    y: offset,
                    width: bounds.size.width,
                    height: height
                )
                offset += height
            }
        }
        
    }
    
}

extension KKInputListView {
    
    func update(view: UI.View.Input.List) {
        self.update(frame: view.frame)
        self.update(transform: view.transform)
        self.update(items: view.items)
        self.update(selected: view.selected, userInteraction: false)
        self.update(textFont: view.textFont)
        self.update(textColor: view.textColor)
        self.update(textInset: view.textInset)
        self.update(placeholder: view.placeholder)
        self.update(placeholderInset: view.placeholderInset)
        self.update(alignment: view.alignment)
        self.update(toolbar: view.toolbar)
        self.kkDelegate = view
    }
    
    func update(frame: Rect) {
        self.frame = frame.cgRect
    }
    
    func update(transform: UI.Transform) {
        self.layer.setAffineTransform(transform.matrix.cgAffineTransform)
    }
    
    func update(items: [IInputListItem]) {
        self.kkItems = items
    }
    
    func update(selected: IInputListItem?, userInteraction: Bool) {
        self.kkSelected = selected
    }
    
    func update(textFont: UI.Font) {
        self.font = textFont.native
    }
    
    func update(textColor: UI.Color) {
        self.textColor = textColor.native
    }
    
    func update(textInset: Inset) {
        self.kkTextInset = textInset.uiEdgeInsets
    }
    
    func update(placeholder: UI.View.Input.Placeholder?) {
        if let placeholder = placeholder {
            self.attributedPlaceholder = NSAttributedString(string: placeholder.text, attributes: [
                .font: placeholder.font.native,
                .foregroundColor: placeholder.color.native
            ])
        } else {
            self.attributedPlaceholder = nil
        }
    }
    
    func update(placeholderInset: Inset?) {
        self.kkPlaceholderInset = placeholderInset?.uiEdgeInsets
    }
    
    func update(alignment: UI.Text.Alignment) {
        self.textAlignment = alignment.nsTextAlignment
    }
    
    func update(toolbar: UI.View.Input.Toolbar?) {
        self.kkAccessoryView.kkToolbarView = toolbar?.native
    }
    
    func cleanup() {
        self.kkDelegate = nil
    }
    
}

private extension KKInputListView {
    
    func _applyText() {
        if let selected = self.kkSelected {
            self.text = selected.title
        } else {
            self.text = nil
        }
    }
    
}

extension KKInputListView : UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.kkDelegate?.beginEditing(self)
        if self.kkSelected == nil, let firstItem = self.kkItems.first {
            self.kkDelegate?.select(self, item: firstItem)
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.kkDelegate?.endEditing(self)
    }
    
}

extension KKInputListView : UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.kkItems.count
    }
    
}

extension KKInputListView : UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.kkItems[row].title
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let selected = self.kkItems[row]
        if self.kkSelected !== selected {
            self.kkDelegate?.select(self, item: selected)
        }
    }
    
}

#endif
