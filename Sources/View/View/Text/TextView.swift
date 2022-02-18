//
//  KindKitView
//

import Foundation
import KindKitCore
import KindKitMath

public class TextView : ITextView {
    
    public private(set) unowned var layout: ILayout?
    public unowned var item: LayoutItem?
    public var native: NativeView {
        return self._view
    }
    public var isLoaded: Bool {
        return self._reuse.isLoaded
    }
    public var bounds: RectFloat {
        guard self.isLoaded == true else { return .zero }
        return RectFloat(self._view.bounds)
    }
    public private(set) var isVisible: Bool
    public var isHidden: Bool {
        didSet(oldValue) {
            guard self.isHidden != oldValue else { return }
            self.setNeedForceLayout()
        }
    }
    public var width: DimensionBehaviour? {
        didSet {
            guard self.width != oldValue else { return }
            guard self.isLoaded == true else { return }
            self._cacheAvailable = nil
            self._cacheSize = nil
            self.setNeedForceLayout()
        }
    }
    public var height: DimensionBehaviour? {
        didSet {
            guard self.height != oldValue else { return }
            guard self.isLoaded == true else { return }
            self._cacheAvailable = nil
            self._cacheSize = nil
            self.setNeedForceLayout()
        }
    }
    public var text: String {
        didSet {
            guard self.text != oldValue else { return }
            guard self.isLoaded == true else { return }
            self._view.update(text: self.text)
            self._cacheAvailable = nil
            self._cacheSize = nil
            self.setNeedForceLayout()
        }
    }
    public var textFont: Font {
        didSet {
            guard self.textFont != oldValue else { return }
            guard self.isLoaded == true else { return }
            self._view.update(textFont: self.textFont)
            self._cacheAvailable = nil
            self._cacheSize = nil
            self.setNeedForceLayout()
        }
    }
    public var textColor: Color {
        didSet {
            guard self.textColor != oldValue else { return }
            guard self.isLoaded == true else { return }
            self._view.update(textColor: self.textColor)
        }
    }
    public var alignment: TextAlignment {
        didSet {
            guard self.alignment != oldValue else { return }
            guard self.isLoaded == true else { return }
            self._view.update(alignment: self.alignment)
            self.setNeedLayout()
        }
    }
    public var lineBreak: TextLineBreak {
        didSet {
            guard self.lineBreak != oldValue else { return }
            guard self.isLoaded == true else { return }
            self._view.update(lineBreak: self.lineBreak)
            self.setNeedForceLayout()
        }
    }
    public var numberOfLines: UInt {
        didSet {
            guard self.numberOfLines != oldValue else { return }
            guard self.isLoaded == true else { return }
            self._view.update(numberOfLines: self.numberOfLines)
            self.setNeedForceLayout()
        }
    }
    public var color: Color? {
        didSet {
            guard self.isLoaded == true else { return }
            self._view.update(color: self.color)
        }
    }
    public var border: ViewBorder {
        didSet {
            guard self.isLoaded == true else { return }
            self._view.update(border: self.border)
        }
    }
    public var cornerRadius: ViewCornerRadius {
        didSet {
            guard self.isLoaded == true else { return }
            self._view.update(cornerRadius: self.cornerRadius)
            self._view.updateShadowPath()
        }
    }
    public var shadow: ViewShadow? {
        didSet {
            guard self.isLoaded == true else { return }
            self._view.update(shadow: self.shadow)
            self._view.updateShadowPath()
        }
    }
    public var alpha: Float {
        didSet {
            guard self.isLoaded == true else { return }
            self._view.update(alpha: self.alpha)
        }
    }
    
    private var _reuse: ReuseItem< Reusable >
    private var _view: Reusable.Content {
        return self._reuse.content()
    }
    private var _onAppear: (() -> Void)?
    private var _onDisappear: (() -> Void)?
    private var _onVisible: (() -> Void)?
    private var _onVisibility: (() -> Void)?
    private var _onInvisible: (() -> Void)?
    private var _cacheAvailable: SizeFloat?
    private var _cacheSize: SizeFloat?
    
    public init(
        reuseBehaviour: ReuseItemBehaviour = .unloadWhenDisappear,
        reuseName: String? = nil,
        width: DimensionBehaviour? = nil,
        height: DimensionBehaviour? = nil,
        text: String,
        textFont: Font,
        textColor: Color,
        alignment: TextAlignment = .left,
        lineBreak: TextLineBreak = .wordWrapping,
        numberOfLines: UInt = 0,
        color: Color? = Color(r: 0.0, g: 0.0, b: 0.0, a: 0.0),
        border: ViewBorder = .none,
        cornerRadius: ViewCornerRadius = .none,
        shadow: ViewShadow? = nil,
        alpha: Float = 1,
        isHidden: Bool = false
    ) {
        self.isVisible = false
        self.width = width
        self.height = height
        self.text = text
        self.textFont = textFont
        self.textColor = textColor
        self.alignment = alignment
        self.lineBreak = lineBreak
        self.numberOfLines = numberOfLines
        self.color = color
        self.border = border
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.alpha = alpha
        self.isHidden = isHidden
        self._reuse = ReuseItem(behaviour: reuseBehaviour, name: reuseName)
        self._reuse.configure(owner: self)
    }
    
    deinit {
        self._reuse.destroy()
    }
    
    public func loadIfNeeded() {
        self._reuse.loadIfNeeded()
    }
    
    public func size(available: SizeFloat) -> SizeFloat {
        guard self.isHidden == false else { return .zero }
        if let cacheAvailable = self._cacheAvailable, let cacheSize = self._cacheSize {
            if cacheAvailable == available {
                return cacheSize
            } else {
                self._cacheAvailable = nil
                self._cacheSize = nil
            }
        }
        let size: SizeFloat
        if let width = self.width, let height = self.height {
            size = available.apply(width: width, height: height)
        } else if let width = self.width {
            let availableSize = SizeFloat(
                width: width.value(available.width) ?? 0,
                height: available.height
            )
            let textSize = self.text.size(font: self.textFont, available: availableSize)
            size = SizeFloat(
                width: availableSize.width,
                height: textSize.height
            )
        } else if let height = self.height {
            let availableSize = SizeFloat(
                width: available.width,
                height: height.value(available.height) ?? 0
            )
            let textSize = self.text.size(font: self.textFont, available: availableSize)
            size = SizeFloat(
                width: textSize.width,
                height: availableSize.height
            )
        } else {
            size = self.text.size(font: self.textFont, available: available)
        }
        self._cacheAvailable = available
        self._cacheSize = size
        return size
    }
    
    public func appear(to layout: ILayout) {
        self.layout = layout
        self._onAppear?()
    }
    
    public func disappear() {
        self._reuse.disappear()
        self.layout = nil
        self._onDisappear?()
    }
    
    public func visible() {
        self.isVisible = true
        self._onVisible?()
    }
    
    public func visibility() {
        self._onVisibility?()
    }
    
    public func invisible() {
        self.isVisible = false
        self._onInvisible?()
    }
    
    @discardableResult
    public func width(_ value: DimensionBehaviour?) -> Self {
        self.width = value
        return self
    }
    
    @discardableResult
    public func height(_ value: DimensionBehaviour?) -> Self {
        self.height = value
        return self
    }
    
    @discardableResult
    public func text(_ value: String) -> Self {
        self.text = value
        return self
    }
    
    @discardableResult
    public func textFont(_ value: Font) -> Self {
        self.textFont = value
        return self
    }
    
    @discardableResult
    public func textColor(_ value: Color) -> Self {
        self.textColor = value
        return self
    }
    
    @discardableResult
    public func alignment(_ value: TextAlignment) -> Self {
        self.alignment = value
        return self
    }
    
    @discardableResult
    public func lineBreak(_ value: TextLineBreak) -> Self {
        self.lineBreak = value
        return self
    }
    
    @discardableResult
    public func numberOfLines(_ value: UInt) -> Self {
        self.numberOfLines = value
        return self
    }
    
    @discardableResult
    public func color(_ value: Color?) -> Self {
        self.color = value
        return self
    }
    
    @discardableResult
    public func border(_ value: ViewBorder) -> Self {
        self.border = value
        return self
    }
    
    @discardableResult
    public func cornerRadius(_ value: ViewCornerRadius) -> Self {
        self.cornerRadius = value
        return self
    }
    
    @discardableResult
    public func shadow(_ value: ViewShadow?) -> Self {
        self.shadow = value
        return self
    }
    
    @discardableResult
    public func alpha(_ value: Float) -> Self {
        self.alpha = value
        return self
    }
    
    @discardableResult
    public func hidden(_ value: Bool) -> Self {
        self.isHidden = value
        return self
    }
    
    @discardableResult
    public func onAppear(_ value: (() -> Void)?) -> Self {
        self._onAppear = value
        return self
    }
    
    @discardableResult
    public func onDisappear(_ value: (() -> Void)?) -> Self {
        self._onDisappear = value
        return self
    }
    
    @discardableResult
    public func onVisible(_ value: (() -> Void)?) -> Self {
        self._onVisible = value
        return self
    }
    
    @discardableResult
    public func onVisibility(_ value: (() -> Void)?) -> Self {
        self._onVisibility = value
        return self
    }
    
    @discardableResult
    public func onInvisible(_ value: (() -> Void)?) -> Self {
        self._onInvisible = value
        return self
    }

}
