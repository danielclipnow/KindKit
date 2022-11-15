//
//  KindKit
//

import Foundation

extension UI.Container {
    
    final class BookItem {
        
        var container: IUIBookContentContainer
        var view: IUIView
        var viewItem: UI.Layout.Item
        
        init(
            _ container: IUIBookContentContainer
        ) {
            self.container = container
            self.view = container.view
            self.viewItem = UI.Layout.Item(container.view)
        }
        
    }
    
}

extension UI.Container.BookItem : Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
}

extension UI.Container.BookItem : Equatable {
    
    static func == (lhs: UI.Container.BookItem, rhs: UI.Container.BookItem) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
}
