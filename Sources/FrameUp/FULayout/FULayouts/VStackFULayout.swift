//
//  VStackFULayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

/// A FrameUp layout version of `VStackLayout`. Useful when you want to toggle between different FrameUp layouts.
@available(iOS, introduced: 14, deprecated: 16, message: "VStackFULayout can be replaced with SwiftUI VStackLayout")
@available(macOS, introduced: 11, deprecated: 13, message: "VStackFULayout can be replaced with SwiftUI VStackLayout")
@available(watchOS, introduced: 7, deprecated: 9, message: "VStackFULayout can be replaced with SwiftUI VStackLayout")
@available(tvOS, introduced: 14, deprecated: 16, message: "VStackFULayout can be replaced with SwiftUI VStackLayout")
@available(visionOS, introduced: 1, deprecated: 1, message: "VStackFULayout can be replaced with SwiftUI VStackLayout")
public struct VStackFULayout: FULayout, Sendable {
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
        self.alignment = alignment.replacingJustification()
        self.spacing = spacing ?? 10
        self.maxWidth = maxWidth
        self.maxItemHeight = maxItemHeight
    }
    
    public func contentOffsets(sizes: [Int: CGSize]) -> [Int: CGPoint] {
        var column = Column(alignment: .init(horizontal: alignment, vertical: .top), minSpacing: spacing)
        
        sizes.forEach { column.append($0) }
        
        return column.contentOffsets(columnXOffset: 0)
    }
}
