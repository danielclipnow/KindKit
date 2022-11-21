//
//  KindKit
//

#if os(macOS)

import AppKit

extension UI.View.Text {
    
    struct Reusable : IUIReusable {
        
        typealias Owner = UI.View.Text
        typealias Content = KKTextView

        static var reuseIdentificator: String {
            return "UI.View.Text"
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

final class KKTextView : NSTextView {
    
    weak var kkDelegate: KKControlViewDelegate?
    override var alignmentRectInsets: NSEdgeInsets {
        return .init()
    }
    override var isFlipped: Bool {
        return true
    }
    
    private let _textStorage: NSTextStorage
    private let _textContainer: NSTextContainer
    private let _layoutManager: NSLayoutManager
    
    override init(frame: CGRect) {
        self._textStorage = NSTextStorage()
        self._textContainer = NSTextContainer(containerSize: frame.size)
        self._textContainer.lineFragmentPadding = 0
        
        self._layoutManager = NSLayoutManager()
        self._layoutManager.addTextContainer(self._textContainer)
        self._textStorage.addLayoutManager(self._layoutManager)
        
        super.init(frame: frame, textContainer: self._textContainer)
        
        self.textContainerInset = .zero
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.drawsBackground = true
        self.isEditable = false
        self.isSelectable = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        self._textContainer.containerSize = newSize
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
    
}

extension KKTextView {
    
    func update(view: UI.View.Text) {
        self.update(text: view.text)
        self.update(textFont: view.textFont)
        self.update(textColor: view.textColor)
        self.update(alignment: view.alignment)
        self.update(lineBreak: view.lineBreak)
        self.update(numberOfLines: view.numberOfLines)
        self.update(color: view.color)
        self.update(alpha: view.alpha)
    }
    
    func update(text: String) {
        self.string = text
    }
    
    func update(textFont: UI.Font) {
        self.font = textFont.native
    }
    
    func update(textColor: UI.Color) {
        self.textColor = textColor.native
    }
    
    func update(alignment: UI.Text.Alignment) {
        self.alignment = alignment.nsTextAlignment
    }
    
    func update(lineBreak: UI.Text.LineBreak) {
        self._textContainer.lineBreakMode = lineBreak.nsLineBreakMode
    }
    
    func update(numberOfLines: UInt) {
        self._textContainer.maximumNumberOfLines = Int(numberOfLines)
    }
    
    func update(color: UI.Color?) {
        if let color = color {
            self.backgroundColor = color.native
        } else {
            self.backgroundColor = .clear
        }
    }
    
    func update(alpha: Float) {
        self.alphaValue = CGFloat(alpha)
    }
    
    func cleanup() {
    }
    
}

#endif
