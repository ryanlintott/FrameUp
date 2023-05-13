//
//  SwiftUIView.swift
//  
//
//  Created by Ryan Lintott on 2023-05-12.
//

import SwiftUI

@available(iOS 16, macOS 13, *)
public struct VFlowLayout: LayoutFromFULayout {
    public let alignment: FUAlignment
    public let horizontalSpacing: CGFloat?
    public let verticalSpacing: CGFloat?
    
    /// Creates a layout that arranges views in a column, adding columns when needed.
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
