//
//  KindKit
//

import Foundation

public struct Percent : Hashable {
    
    public var value: Double
    
    public init(_ value: Double) {
        self.value = value
    }
    
}

public extension Percent {
    
    @inlinable
    static var zero: Self {
        return Percent(0.0)
    }
    
    @inlinable
    static var half: Self {
        return Percent(0.5)
    }
    
    @inlinable
    static var one: Self {
        return Percent(1.0)
    }

}

public extension Percent {
    
    @inlinable
    var isZero: Bool {
        return self ~~ .zero
    }
    
    @inlinable
    var isHalf: Bool {
        return self ~~ .half
    }
    
    @inlinable
    var isOne: Bool {
        return self ~~ .one
    }
    
    @inlinable
    var invert: Self {
        return .one - self
    }
    
    @inlinable
    var normalized: Self {
        return Percent(self.value.clamp(0, 1))
    }
    
}

public extension Percent {
    
    @inlinable
    func clamp(_ lower: Self, _ upper: Self) -> Self {
        return Percent(self.value.clamp(lower.value, upper.value))
    }
    
}

public extension Percent {
    
    @inlinable
    static prefix func - (arg: Self) -> Self {
        return Percent(-arg.value)
    }
    
    @inlinable
    static func + (lhs: Self, rhs: Self) -> Self {
        return Percent(lhs.value + rhs.value)
    }
    
    @inlinable
    static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }
    
    @inlinable
    static func - (lhs: Self, rhs: Self) -> Self {
        return Percent(lhs.value - rhs.value)
    }
    
    @inlinable
    static func -= (lhs: inout Self, rhs: Self) {
        lhs = lhs - rhs
    }
    
    @inlinable
    static func * (lhs: Self, rhs: Self) -> Self {
        return Percent(lhs.value * rhs.value)
    }
    
    @inlinable
    static func *= (lhs: inout Self, rhs: Self) {
        lhs = lhs * rhs
    }
    
    @inlinable
    static func / (lhs: Self, rhs: Self) -> Self {
        return Percent(lhs.value / rhs.value)
    }
    
    @inlinable
    static func /= (lhs: inout Self, rhs: Self) {
        lhs = lhs / rhs
    }
    
}

extension Percent : INearEqutable {
    
    @inlinable
    public static func ~~ (lhs: Self, rhs: Self) -> Bool {
        return lhs.value ~~ rhs.value
    }
    
}

extension Percent : Comparable {
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.value < rhs.value
    }
    
}