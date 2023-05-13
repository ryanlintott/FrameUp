//
//  HFlowLayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2023-05-12.
//

import SwiftUI

@available(iOS 16, macOS 13, *)
public struct HFlowLayout: LayoutFromFULayout {
    public let alignment: FUAlignment
    public let horizontalSpacing: CGFloat?
    public let verticalSpacing: CGFloat?
    
    /// Creates a layout that arranges views in a row, adding rows when needed.
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
