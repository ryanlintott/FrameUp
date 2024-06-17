//
//  HStackFULayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

/// A FrameUp layout version of `HStackLayout`. Useful when you want to toggle between different FrameUp layouts.
public struct HStackFULayout: FULayout, Sendable {
    typealias Row = FULayoutRow
    
    public let alignment: FUVerticalAlignment
    public let spacing: CGFloat
    public let maxHeight: CGFloat
    public let maxItemWidth: CGFloat?
    
    public var maxItemHeight: CGFloat? { maxHeight }
    public let fixedSize: Axis.Set = .horizontal
    
    /// Creates a FrameUp layout version of `HStackLayout`.
    /// - Parameters:
    ///   - alignment: Vertical alignment of elements.
    ///   - spacing: Minimum horizontal spacing between views. Default is 10
    ///   - maxHeight: Maximum height (can be obtained through a `HeightReader`).
    ///   - maxItemWidth: Maximum width for each child view. Default is infinity.
    public init(
        alignment: FUVerticalAlignment = .center,
        spacing: CGFloat? = nil,
        maxHeight: CGFloat,
        maxItemWidth: CGFloat? = nil
    ) {
        self.alignment = alignment.replacingJustification()
        self.spacing = spacing ?? 10
        self.maxHeight = maxHeight
        self.maxItemWidth = maxItemWidth
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        var row = Row(alignment: .init(horizontal: .leading, vertical: alignment), minSpacing: spacing)
        
        sizes.forEach { row.append($0) }
        
        return row.contentOffsets(rowYOffset: 0)
    }
}
