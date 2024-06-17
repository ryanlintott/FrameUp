//
//  AnyFULayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-18.
//

import SwiftUI

/**
 A type-erased instance of the FrameUp layout protocol.
 
 If you want to make a view that can toggle between layouts, wrap each one in AnyLayout.
 */
public struct AnyFULayout: FULayout {
    /// The name of the wrapped layout (just used as a label)
    public let fuLayoutName: String
    public let layoutHash: Int
    public let fixedSize: Axis.Set
    public let maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat?
    /// A closure that holds the layout function for the wrapped layout.
    private let contentOffsets: ([Int : CGSize]) -> [Int : CGPoint]
    
    /// Creates a type-erased FrameUp layout.
    /// - Parameter layout: FrameUp layout that will be type-erased.
    public init<L: FULayout>(_ layout: L) {
        fuLayoutName = String(describing: L.self)
        fixedSize = layout.fixedSize
        maxItemWidth = layout.maxItemWidth
        maxItemHeight = layout.maxItemHeight
        contentOffsets = layout.contentOffsets
        layoutHash = layout.hashValue
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        contentOffsets(sizes)
    }
    
    public static func == (lhs: AnyFULayout, rhs: AnyFULayout) -> Bool {
        lhs.fuLayoutName == rhs.fuLayoutName
        && lhs.layoutHash == rhs.layoutHash
        && lhs.fixedSize == rhs.fixedSize
        && lhs.maxItemWidth == rhs.maxItemWidth
        && lhs.maxItemHeight == rhs.maxItemHeight
    }
    
    public func hash(into hasher: inout Hasher) {
        /// Use the same hash as the inherited layout
        hasher.combine(layoutHash)
        /// Adding a string of this type name will differentiate AnyFULayout(layout) from layout
        hasher.combine(String(describing: Self.self))
    }
}
