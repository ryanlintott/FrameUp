//
//  VStackFULayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

/// A FrameUp layout version of `VStackLayout`. Useful when you want to toggle between different FrameUp layouts.
public struct VStackFULayout: FULayout {
    typealias Column = FULayoutColumn
    
    public let alignment: FUHorizontalAlignment
    public let spacing: CGFloat
    public let maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat?

    public let fixedSize: Axis.Set = .vertical
    
    /// Creates a FrameUp layout version of `HStackLayout`.
    /// - Parameters:
    ///   - alignment: Horizontal alignment of elements.
    ///   - spacing: Minimum vertical spacing between views. Default is 10
    ///   - maxWidth: Maximum width (can be obtained through a `WidthReader`).
    ///   - maxItemHeight: Maximum height for each child view. Default is infinity.
    public init(
        alignment: FUHorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        maxWidth: CGFloat,
        maxItemHeight: CGFloat? = nil
    ) {
        self.alignment = alignment
        self.spacing = spacing ?? 10
        self.maxItemHeight = maxItemHeight
        self.maxItemWidth = maxWidth
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        var column = Column(alignment: .init(horizontal: alignment, vertical: .top), spacing: spacing, width: maxItemWidth ?? .infinity)
        
        sizes.forEach { column.append($0) }
        
        return column.contentOffsets(columnXOffset: 0)
    }
}

@available(iOS 16, *)
extension VStackFULayout {
    /// SwiftUI layout using the same alignment and spacing values.
    var layout: VStackLayout {
        VStackLayout(alignment: alignment.alignment, spacing: spacing)
    }
}
