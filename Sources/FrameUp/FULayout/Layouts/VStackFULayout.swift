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
    public let maxWidth: CGFloat
    public let maxItemHeight: CGFloat?

    public var maxItemWidth: CGFloat? { maxWidth }
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
        self.maxWidth = maxWidth
        self.maxItemHeight = maxItemHeight
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        var column = Column(alignment: .init(horizontal: alignment, vertical: .top), spacing: spacing)
        
        sizes.forEach { column.append($0) }
        
        return column.contentOffsets(columnXOffset: 0)
    }
}

@available(iOS 16, macOS 13, *)
extension VStackFULayout: Layout { }
