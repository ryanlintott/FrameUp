//
//  SwiftUIView.swift
//
//
//  Created by Ryan Lintott on 2023-05-12.
//

import SwiftUI

/**
 A layout that arranges views into rows, adding views to the shortest row.
 
 Example:
 ```swift
 HMasonryLayout(rows: 3) {
    ForEach(["Hello", "World", "More Text"], id: \.self) { item in
        Text(item.value)
    }
 }
 ```
 */
@available(iOS 16, macOS 13, watchOS 9, tvOS 16, *)
public struct HMasonryLayout: LayoutFromFULayout {
    public let alignment: FUAlignment
    public let rows: Int
    public let horizontalSpacing: CGFloat?
    public let verticalSpacing: CGFloat?
    
    /// Creates a layout that arranges views into rows, adding views to the shortest row.
    /// - Parameters:
    ///   - alignment: Used to align rows horizontally relative to each other. Default is leading.
    ///   - rows: Number of rows to place views in.
    ///   - maxHeight: Maximum height containing all rows (can be obtained through a `HeightReader`).
    ///   - horizontalSpacing: Minimum horizontal spacing between columns.
    ///   - verticalSpacing: Vertical spacing between views in a column
    public init(
        alignment: FUAlignment = .leading,
        rows: Int,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil
    ) {
        self.alignment = alignment.replacingVerticalJustification()
        self.rows = max(1, rows)
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }
    
    public func fuLayout(maxSize: CGSize) -> HMasonry {
        HMasonry(
            alignment: alignment,
            rows: rows,
            maxHeight: maxSize.height,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing
        )
    }
}
