//
//  KindKitMath
//

import Foundation

public typealias Box2Float = Box2< Float >
public typealias Box2Double = Box2< Double >

public struct Box2< ValueType: IScalar & Hashable > : Hashable {
    
    public var lower: Point< ValueType >
    public var upper: Point< ValueType >
    
    @inlinable
    public init() {
        self.lower = .zero
        self.upper = .zero
    }
    
    @inlinable
    public init(lower: Point< ValueType >, upper: Point< ValueType >) {
        self.lower = lower
        self.upper = upper
    }
    
    @inlinable
    public init(point1: Point< ValueType >, point2: Point< ValueType >) {
        self.lower = point1.min(point2)
        self.upper = point1.max(point2)
    }
    
}

public extension Box2 {
    
    @inlinable
    static var empty: Self {
        return Box2(lower: .infinity, upper: -.infinity)
    }
    
}

public extension Box2 {
    
    @inlinable
    var isEmpty: Bool {
        return self.lower.x > self.upper.x || self.lower.y > self.upper.y
    }
    
    @inlinable
    var width: ValueType {
        return Swift.max(self.upper.x - self.lower.x, 0)
    }
    
    @inlinable
    var height: ValueType {
        return Swift.max(self.upper.y - self.lower.y, 0)
    }
    
    @inlinable
    var topLeft: Point< ValueType > {
        return Point(x: self.lower.x, y: self.lower.y)
    }
    
    @inlinable
    var top: Point< ValueType > {
        return Point(x: self.lower.x + self.width / 2, y: self.lower.y)
    }
    
    @inlinable
    var topRight: Point< ValueType > {
        return Point(x: self.upper.x, y: self.lower.y)
    }
    
    @inlinable
    var left: Point< ValueType > {
        return Point(x: self.lower.x, y: self.lower.y + self.height / 2)
    }
    
    @inlinable
    var center: Point< ValueType > {
        return Point(x: self.lower.x + self.width / 2, y: self.lower.y + self.height / 2)
    }
    
    @inlinable
    var right: Point< ValueType > {
        return Point(x: self.upper.x, y: self.lower.y + self.height / 2)
    }
    
    @inlinable
    var bottomLeft: Point< ValueType > {
        return Point(x: self.lower.x, y: self.upper.y)
    }
    
    @inlinable
    var bottom: Point< ValueType > {
        return Point(x: self.lower.x + self.width / 2, y: self.lower.y + self.height)
    }
    
    @inlinable
    var bottomRight: Point< ValueType > {
        return Point(x: self.upper.x, y: self.upper.y)
    }
    
    @inlinable
    var area: ValueType {
        let size = self.size
        return size.width * size.height
    }
    
    @inlinable
    var size: Size< ValueType > {
        return Size(width: self.width, height: self.height)
    }
    
    @inlinable
    var centeredForm: (center: Point< ValueType >, extend: Point< ValueType >) {
        return (
            center: (self.upper + self.lower) * 0.5,
            extend: (self.upper - self.lower) * 0.5
        )
    }
    
}

public extension Box2 {
    
    @inlinable
    func isContains(_ point: Point< ValueType >) -> Bool {
        guard point.x >= self.lower.x && point.x <= self.upper.x else { return false }
        guard point.y >= self.lower.y && point.y <= self.upper.y else { return false }
        return true
    }
    
    @inlinable
    func isIntersects(_ other: Self) -> Bool {
        return Intersection2.possibly(self, other)
    }
    
    @inlinable
    func isIntersects(_ other: Line2< ValueType >) -> Bool {
        return Intersection2.possibly(other, self)
    }
    
    @inlinable
    func intersection(_ other: Line2< ValueType >) -> Intersection2< ValueType >.LineToBox {
        return Intersection2.find(other, self)
    }
    
    @inlinable
    func union(_ other: Self) -> Self {
        return Box2(
            lower: self.lower.min(other.lower),
            upper: self.upper.max(other.upper)
        )
    }
    
    @inlinable
    func union(_ other: Point< ValueType >) -> Self {
        return Box2(
            lower: self.lower.min(other),
            upper: self.upper.max(other)
        )
    }
    
    @inlinable
    func intersection(_ other: Self) -> Self? {
        switch Intersection2.find(self, other) {
        case .none: return nil
        case .box(let box): return box
        }
    }
    
    @inlinable
    func inset(_ inset: ValueType) -> Self {
        return Box2(lower: self.lower - inset, upper: self.upper + inset)
    }
    
    @inlinable
    func inset(_ inset: Distance< ValueType >) -> Self {
        return self.inset(inset.real)
    }
    
}
