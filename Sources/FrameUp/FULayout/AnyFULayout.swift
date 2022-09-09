//
//  AnyFULayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-18.
//

import SwiftUI

/// A type-erased instance of the FrameUp layout protocol.
public struct AnyFULayout: FULayout {
    /// The name of the wrapped layout (just used as a label)
    public let fuLayoutName: String
    /// An id used to ensure every instance is unique. This is used to ensure layout views are recalculated.
    public let id = UUID()
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
}
