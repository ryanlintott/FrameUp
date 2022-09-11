//
//  HFlowEach.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-09-11.
//

import SwiftUI

/// A view that creates views based on a collection of data the arranges them in a row, adding rows when needed.
///
/// `_HFlow` is an alternative that uses `_VariadicView` and does not require data.
public struct HFlowEach<Data: RandomAccessCollection, Content: View>: FULayoutForEachView where Data.Element: Identifiable, Data.Index == Int {
    public let data: Data
    public let layout: HFlowFULayout
    public let content: (Data.Element) -> Content
    
    /// Creates a view that arranges views in a row, adding rows when needed.
    /// - Parameters:
    ///   - data: Collection of data eg. an array of strings.
    ///   - alignment: Used to align views vertically in their rows and align rows horizontally relative to each other. Default is top leading.
    ///   - maxWidth: Maximum width for a row (can be obtained through a `WidthReader`).
    ///   - maxItemWidth: Maximum width for each child view default is the maximum row width.
    ///   - horizontalSpacing: Minimum horizontal spacing between views in a row.
    ///   - verticalSpacing: Vertical spacing between rows.
    public init(
        _ data: Data,
        alignment: Alignment = .topLeading,
        maxWidth: CGFloat,
        maxItemWidth: CGFloat? = nil,
        horizontalSpacing: CGFloat? = nil,
        verticalSpacing: CGFloat? = nil,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
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
