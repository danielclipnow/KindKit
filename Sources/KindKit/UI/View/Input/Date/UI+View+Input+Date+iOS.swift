//
//  KindKit
//

#if os(iOS)

import UIKit

extension UI.View.Input.Date {
    
    struct Reusable : IUIReusable {
        
        typealias Owner = UI.View.Input.Date
        typealias Content = KKInputDateView

        static var reuseIdentificator: String {
            return "UI.View.Input.Date"
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

final class KKInputDateView : UITextField {
    
    weak var kkDelegate: KKInputDateViewDelegate?
    let kkAccessoryView: KKAccessoryView
    var kkFormatter: DateFormatter? {
        didSet {
            guard self.kkFormatter != oldValue else { return }
            if let formatter = self.kkFormatter {
                self.kkPicker.calendar = formatter.calendar
                self.kkPicker.locale = formatter.locale
                self.kkPicker.timeZone = formatter.timeZone
            }
            self._applyText()
        }
    }
    var kkSelected: Foundation.Date? {
        didSet {
            guard self.kkSelected != oldValue else { return }
            if let selected = self.kkSelected {
                self.kkPicker.date = selected
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

    private var kkPicker: UIDatePicker
    
    override init(frame: CGRect) {
        self.kkAccessoryView = .init(
            frame: .init(
                x: 0,
                y: 0,
                width: UIScreen.main.bounds.width,
                height: 0
            )
        )
        self.kkPicker = UIDatePicker()

        super.init(frame: frame)
        
        self.kkAccessoryView.kkInput = self
        self.inputAccessoryView = self.kkAccessoryView
        self.clipsToBounds = true
        self.delegate = self
        
        if #available(iOS 13.4, *) {
            self.kkPicker.preferredDatePickerStyle = .wheels
        }
        self.kkPicker.addTarget(self, action: #selector(self._changed(_:)), for: .valueChanged)
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

extension KKInputDateView {
    
    final class KKAccessoryView : UIInputView {
        
        weak var kkInput: KKInputDateView?
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

extension KKInputDateView {
    
    func update(view: UI.View.Input.Date) {
        self.update(frame: view.frame)
        self.update(transform: view.transform)
        self.update(mode: view.mode)
        self.update(formatter: view.formatter)
        self.update(minimum: view.minimum)
        self.update(maximum: view.maximum)
        self.update(selected: view.selected)
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
    
    func update(mode: UI.View.Input.Date.Mode) {
        self.kkPicker.datePickerMode = mode.datePickerMode
    }
    
    func update(formatter: DateFormatter) {
        self.kkFormatter = formatter
    }
    
    func update(minimum: Foundation.Date?) {
        self.kkPicker.minimumDate = minimum
    }
    
    func update(maximum: Foundation.Date?) {
        self.kkPicker.maximumDate = maximum
    }
    
    func update(selected: Foundation.Date?) {
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

private extension KKInputDateView {
    
    func _applyText() {
        if let formatter = self.kkFormatter, let selected = self.kkSelected {
            self.text = formatter.string(from: selected)
        } else {
            self.text = nil
        }
    }
        
    @objc
    func _changed(_ sender: UIDatePicker) {
        self.kkDelegate?.select(self, date: sender.date)
    }
    
}

extension KKInputDateView : UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.kkDelegate?.beginEditing(self)
        if self.kkSelected == nil {
            self.kkDelegate?.select(self, date: self.kkPicker.date)
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.kkDelegate?.endEditing(self)
    }
    
}

#endif
