//
//  KindKit
//

import Foundation

public extension UI.Layout.Composition {
    
    struct VAccessory {
        
        public var leading: IUICompositionLayoutEntity?
        public var center: IUICompositionLayoutEntity
        public var trailing: IUICompositionLayoutEntity?
        public var filling: Bool = true
        
        public init(
            leading: IUICompositionLayoutEntity? = nil,
            center: IUICompositionLayoutEntity,
            trailing: IUICompositionLayoutEntity? = nil,
            filling: Bool = true
        ) {
            self.leading = leading
            self.center = center
            self.trailing = trailing
            self.filling = filling
        }
        
    }
    
}

extension UI.Layout.Composition.VAccessory : IUICompositionLayoutEntity {
    
    public func invalidate(item: UI.Layout.Item) {
        self.leading?.invalidate(item: item)
        self.center.invalidate(item: item)
        self.trailing?.invalidate(item: item)
    }
    
    @discardableResult
    public func layout(bounds: RectFloat) -> SizeFloat {
        let leadingSize: SizeFloat
        if let leading = self.leading {
            leadingSize = leading.size(available: bounds.size)
        } else {
            leadingSize = .zero
        }
        let trailingSize: SizeFloat
        if let trailing = self.trailing {
            trailingSize = trailing.size(available: bounds.size)
        } else {
            trailingSize = .zero
        }
        let centerSize = self.center.size(available: SizeFloat(
            width: max(leadingSize.width, bounds.width, trailingSize.width),
            height: bounds.height - (leadingSize.height + trailingSize.height)
        ))
        let base = RectFloat(
            x: bounds.x,
            y: bounds.y,
            width: max(leadingSize.width, centerSize.width, trailingSize.width),
            height: bounds.height
        )
        if let leading = self.leading {
            leading.layout(bounds: RectFloat(
                topLeft: base.topLeft,
                width: base.width,
                height: leadingSize.height
            ))
        }
        if let trailing = self.trailing {
            trailing.layout(bounds: RectFloat(
                bottomLeft: base.bottomLeft,
                width: base.width,
                height: trailingSize.height
            ))
        }
        if self.filling == true {
            self.center.layout(bounds: RectFloat(
                x: base.x,
                y: base.y + leadingSize.height,
                width: base.width,
                height: base.height - (leadingSize.height + trailingSize.height)
            ))
        } else {
            self.center.layout(bounds: RectFloat(
                center: base.center,
                width: base.width,
                height: bounds.height - (max(leadingSize.height, trailingSize.height) * 2)
            ))
        }
        return base.size
    }
    
    public func size(available: SizeFloat) -> SizeFloat {
        let leadingSize: SizeFloat
        if let leading = self.leading {
            leadingSize = leading.size(available: available)
        } else {
            leadingSize = .zero
        }
        let trailingSize: SizeFloat
        if let trailing = self.trailing {
            trailingSize = trailing.size(available: available)
        } else {
            trailingSize = .zero
        }
        let centerSize = self.center.size(available: SizeFloat(
            width: max(leadingSize.width, available.width, trailingSize.width),
            height: available.height - (leadingSize.height + trailingSize.height)
        ))
        return Size(
            width: max(leadingSize.width, centerSize.width, trailingSize.width),
            height: available.height
        )
    }
    
    public func items(bounds: RectFloat) -> [UI.Layout.Item] {
        var items: [UI.Layout.Item] = []
        if let leading = self.leading {
            items.append(contentsOf: leading.items(bounds: bounds))
        }
        if let trailing = self.trailing {
            items.append(contentsOf: trailing.items(bounds: bounds))
        }
        items.append(contentsOf: self.center.items(bounds: bounds))
        return items
    }
    
}

public extension IUICompositionLayoutEntity where Self == UI.Layout.Composition.VAccessory {
    
    @inlinable
    static func vAccessory(
        leading: IUICompositionLayoutEntity? = nil,
        center: IUICompositionLayoutEntity,
        trailing: IUICompositionLayoutEntity? = nil,
        filling: Bool
    ) -> UI.Layout.Composition.VAccessory {
        return .init(
            leading: leading,
            center: center,
            trailing: trailing,
            filling: filling
        )
    }
    
}