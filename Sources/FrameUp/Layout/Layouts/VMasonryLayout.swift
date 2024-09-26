//
//  VMasonryLayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2023-05-12.
//

import SwiftUI

/**
 A `Layout` that arranges views into a set number of columns by adding each view to the shortest column.
 
 Example:
 ```swift
 VMasonryLayout(columns: 3) {
     ForEach(["Hello", "World", "More Text"], id: \.self) { item in
         Text(item.value)
     }
 }
 ```
 */
@available(iOS 16, macOS 13, watchOS 9, tvOS 16, *)
public struct VMasonryLayout: LayoutFromFULayout, Sendable {
    public let alignment: FUAlignment
    public let columns: Int
    public let horizontalSpacing: CGFloat?
    public let verticalSpacing: CGFloat?
    
    /// Creates a `Layout` that arranges views into a set number of columns by adding each view to the shortest column.
    /// - Parameters:
    ///   - alignment: Used to align columns vertically relative to each other. Default is top.
    ///   - columns: Number of columns to place views in.
    ///   - horizontalSpacing: Minimum horizontal spacing between columns.
    ///   - verticalSpacing: Vertical spacing between views in a column
    public init(
        alignment: FUAlignment = .top,
        columns: Int,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil
    ) {
        self.alignment = alignment.replacingHorizontalJustification()
        self.columns = max(1, columns)
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }
    
    public func fuLayout(maxSize: CGSize) -> VMasonry {
        VMasonry(
            alignment: alignment,
            columns: columns,
            maxWidth: maxSize.width,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing
        )
    }
}

@available(iOS 16, macOS 13, watchOS 9, tvOS 16, *)
public extension VMasonryLayout {
    /// Creates a `Layout` that arranges views into a set number of columns by adding each view to the shortest column.
    /// - Parameters:
    ///   - alignment: Used to align columns vertically relative to each other. Default is top.
    ///   - columns: Number of columns to place views in.
    ///   - spacing: Minimum spacing between views.
    init(
        alignment: FUAlignment = .top,
        columns: Int,
        spacing: CGFloat
    ) {
        self.init(alignment: alignment, columns: columns, horizontalSpacing: spacing, verticalSpacing: spacing)
    }
}
