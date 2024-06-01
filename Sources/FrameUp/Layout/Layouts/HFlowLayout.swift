//
//  HFlowLayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2023-05-12.
//

import SwiftUI

/**
 A `Layout` that arranges views in horizontal rows flowing from one to the next with adjustable horizontal and vertical spacing and support for horiztonal and vertical alignment including a justified alignment that will space elements in completed rows evenly.
 
 Each row height will be determined by the tallest view in that row.
 
 Example:
 ```swift
 HFlowLayout {
     ForEach(["Hello", "World", "More Text"], id: \.self) { item in
         Text(item.value)
     }
 }
 ```
 */
@available(iOS 16, macOS 13, watchOS 9, tvOS 16, *)
public struct HFlowLayout: LayoutFromFULayout {
    public let alignment: FUAlignment
    public let horizontalSpacing: CGFloat?
    public let verticalSpacing: CGFloat?
    
    /// Creates a `Layout` that arranges views in horizontal rows flowing from one to the next.
    /// - Parameters:
    ///   - alignment: Used to align views vertically in their rows and align rows horizontally relative to each other. Default is top leading. Vertical justification will act as top alignment.
    ///   - horizontalSpacing: Minimum horizontal spacing between views in a row.
    ///   - verticalSpacing: Vertical spacing between rows.
    public init(
        alignment: FUAlignment = .topLeading,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil
    ) {
        self.alignment = alignment.replacingVerticalJustification()
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }
    
    public func fuLayout(maxSize: CGSize) -> HFlow {
        HFlow(
            alignment: alignment,
            maxWidth: maxSize.width,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing
        )
    }
}

@available(iOS 16, macOS 13, watchOS 9, tvOS 16, *)
public extension HFlowLayout {
    /// Creates a `Layout` that arranges views in horizontal rows flowing from one to the next.
    /// - Parameters:
    ///   - alignment: Used to align views vertically in their rows and align rows horizontally relative to each other. Default is top leading. Vertical justification will act as top alignment.
    ///   - spacing: Minimum spacing between views.
    init(
        alignment: FUAlignment = .topLeading,
        spacing: CGFloat
    ) {
        self.init(alignment: alignment, horizontalSpacing: spacing, verticalSpacing: spacing)
    }
}
