//
//  VFlowLayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2023-05-12.
//

import SwiftUI

/**
 A `Layout` that arranges views in vertical columns flowing from one to the next with adjustable horizontal and vertical spacing and support for horiztonal and vertical alignment including a justified alignment that will space elements in completed columns evenly.
 
 Each column width will be determined by the widest view in that column.

 Example:
 ```swift
 VFlowLayout {
     ForEach(["Hello", "World", "More Text"], id: \.self) { item in
         Text(item.value)
     }
 }
 ```
 */
@available(iOS 16, macOS 13, watchOS 9, tvOS 16, *)
public struct VFlowLayout: LayoutFromFULayout {
    public let alignment: FUAlignment
    public let horizontalSpacing: CGFloat?
    public let verticalSpacing: CGFloat?
    
    /// Creates a `Layout` that arranges views in vertical columns flowing from one to the next
    /// - Parameters:
    ///   - alignment: Used to align views horizontally in their columns and align columns vertically relative to each other. Default is top leading.
    ///   - horizontalSpacing: Minimum horizontal spacing between columns.
    ///   - verticalSpacing: Vertical spacing between views in a column
    public init(
        alignment: FUAlignment = .topLeading,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil
    ) {
        self.alignment = alignment.replacingHorizontalJustification()
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }
    
    public func fuLayout(maxSize: CGSize) -> VFlow {
        VFlow(
            alignment: alignment,
            maxHeight: maxSize.height,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing
        )
    }
}

@available(iOS 16, macOS 13, watchOS 9, tvOS 16, *)
public extension VFlowLayout {
    /// Creates a `Layout` that arranges views in vertical columns flowing from one to the next
    /// - Parameters:
    ///   - alignment: Used to align views horizontally in their columns and align columns vertically relative to each other. Default is top leading.
    ///   - spacing: Minimum spacing between views.
    init(
        alignment: FUAlignment = .topLeading,
        spacing: CGFloat
    ) {
        self.init(alignment: alignment, horizontalSpacing: spacing, verticalSpacing: spacing)
    }
}
