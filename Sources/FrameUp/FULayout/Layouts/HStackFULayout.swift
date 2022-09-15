//
//  HStackFULayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

/// A FrameUp layout version of `HStackLayout`. Useful when you want to toggle between different FrameUp layouts.
///
/// *Only top, center, and bottom alignments are supported.*
public struct HStackFULayout: FULayout {
    typealias Row = FULayoutRow
    
    public let alignment: VerticalAlignment
    public let spacing: CGFloat
    public let maxItemWidth: CGFloat?
    public let maxItemHeight: CGFloat?

    public let fixedSize: Axis.Set = .horizontal
    
    /// Creates a FrameUp layout version of `HStackLayout`.
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this stack. This guide has the same vertical screen coordinate for every subview. *Only top, center, and bottom are supported*.
    ///   - spacing: Minimum horizontal spacing between views. Default is 10
    ///   - maxHeight: Maximum height (can be obtained through a `HeightReader`).
    ///   - maxItemWidth: Maximum width for each child view. Default is infinity.
    public init(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        maxHeight: CGFloat,
        maxItemWidth: CGFloat? = nil
    ) {
        self.alignment = alignment
        self.spacing = spacing ?? 10
        self.maxItemHeight = maxHeight
        self.maxItemWidth = maxItemWidth
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        var row = Row(alignment: Alignment(horizontal: .leading, vertical: alignment), spacing: spacing, height: maxItemHeight ?? .infinity)
        
        sizes.forEach { row.append($0) }
        
        return row.contentOffsets(rowYOffset: 0)
    }
}

@available(iOS 16, *)
extension HStackFULayout {
    /// SwiftUI layout using the same alignment and spacing values.
    var layout: HStackLayout {
        HStackLayout(alignment: alignment, spacing: spacing)
    }
}
