//
//  _HFlow.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-09-10.
//

import SwiftUI

/// A view that arranges views in a row, adding rows when needed.
///
/// The underscore shows that this view uses SwiftUI `_VariadicView` under the hood. If this concerns you, `HFlowEach` is a very similar alternative.
public struct _HFlow<Content: View>: FULayout_View {
    public let layout: HFlowFULayout
    public let content: () -> Content
    
    /// Creates a view that arranges views in a row, adding rows when needed.
    /// - Parameters:
    ///   - alignment: Used to align views vertically in their rows and align rows horizontally relative to each other. Default is top leading.
    ///   - maxWidth: Maximum width for a row (can be obtained through a `WidthReader`).
    ///   - maxItemWidth: Maximum width for each child view default is the maximum row width.
    ///   - horizontalSpacing: Minimum horizontal spacing between views in a row.
    ///   - verticalSpacing: Vertical spacing between rows.
    public init(
        alignment: Alignment = .topLeading,
        maxWidth: CGFloat,
        maxItemWidth: CGFloat? = nil,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        layout = HFlowFULayout(
            alignment: alignment,
            maxWidth: maxWidth,
            maxItemWidth: maxItemWidth,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing
        )
        self.content = content
    }
}
