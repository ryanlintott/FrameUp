//
//  AnyFULayout.swift
//  
//
//  Created by Ryan Lintott on 2022-07-18.
//

import SwiftUI

public struct AnyFULayout: FULayout {
    public let fuLayoutName: String
    public let id = UUID()
    public let fixedSize: Axis.Set
    public let maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat?
    private let contentOffsets: ([Int : CGSize]) -> [Int : CGPoint]
    
    public init<L: FULayout>(_ layout: L) {
        fuLayoutName = String(describing: L.self)
        fixedSize = layout.fixedSize
        maxItemWidth = layout.maxItemWidth
        maxItemHeight = layout.maxItemHeight
        contentOffsets = layout.contentOffsets
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        contentOffsets(sizes)
    }
    
    public static func == (lhs: AnyFULayout, rhs: AnyFULayout) -> Bool {
        lhs.fuLayoutName == rhs.fuLayoutName
        && lhs.id == rhs.id
        && lhs.fixedSize == rhs.fixedSize
        && lhs.maxItemWidth == rhs.maxItemWidth
        && lhs.maxItemHeight == rhs.maxItemHeight
    }
//
//    public func hash(into hasher: inout Hasher) {
//        hasher.combine(fuLayoutName)
//        hasher.combine(hashedLayout)
//    }
}
