//
//  SwiftUIView.swift
//
//
//  Created by Ryan Lintott on 2023-05-12.
//

import SwiftUI

/**
 A layout that arranges views into columns, adding views to the shortest column.
 
 Example:
 ```swift
 VMasonry(columns: 3) {
     ForEach(["Hello", "World", "More Text"], id: \.self) { item in
         Text(item.value)
     }
 }
 ```
 */
@available(iOS 16, macOS 13, watchOS 9, tvOS 16, *)
public struct VMasonryLayout: LayoutFromFULayout {
    public let alignment: FUAlignment
    public let columns: Int
    public let horizontalSpacing: CGFloat?
    public let verticalSpacing: CGFloat?
    
    /// Creates a layout that arranges views columns, adding views to the shortest column.
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
