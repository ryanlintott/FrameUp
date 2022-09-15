//
//  VStackFULayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

/// A FrameUp layout version of `VStackLayout`. Useful when you want to animate between different FrameUp layouts.
///
/// *Only leading, center, and trailing alignments are supported.*
public struct VStackFULayout: FULayout {
    typealias Column = FULayoutColumn
    
    public let alignment: HorizontalAlignment
    public let spacing: CGFloat
    public let maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat?

    public let fixedSize: Axis.Set = .vertical
    
    /// Creates a FrameUp layout version of `HStackLayout`.
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this stack. This guide has the same horizontal screen coordinate for every subview. *Only leading, center, and trailing are supported*.
    ///   - spacing: Minimum vertical spacing between views. Default is 10
    ///   - maxWidth: Maximum width (can be obtained through a `WidthReader`).
    ///   - maxItemHeight: Maximum height for each child view. Default is infinity.
    public init(
        alignment: HorizontalAlignment = .center,
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
        var column = Column(alignment: Alignment(horizontal: alignment, vertical: .top), spacing: spacing, width: maxItemWidth ?? .infinity)
        
        sizes.forEach { column.append($0) }
        
        return column.contentOffsets(columnXOffset: 0)
    }
}

@available(iOS 16, *)
extension VStackFULayout {
    /// SwiftUI layout using the same alignment and spacing values.
    var layout: VStackLayout {
        VStackLayout(alignment: alignment, spacing: spacing)
    }
}
