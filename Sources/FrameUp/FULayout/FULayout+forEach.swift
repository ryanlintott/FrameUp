//
//  FULayout+forEach.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-05-31.
//

import SwiftUI

public extension FULayout {
    /// Creates a FrameUp layout view by computing views on demand from an underlying collection of identified data.
    /// - Parameters:
    ///   - data: Data used to generate views.
    ///   - content: Closure that takes one item from data and generates a view for that item.
    /// - Returns: A  views on demand from an underlying collection of identified data.
    @available(iOS, introduced: 14, deprecated: 16, message: "FULayout can be replaced with SwiftUI Layout equivalent. For example: HFlow -> HFlowLayout")
    @available(macOS, introduced: 11, deprecated: 13, message: "FULayout can be replaced with SwiftUI Layout equivalent. For example: HFlow -> HFlowLayout")
    @available(watchOS, introduced: 7, deprecated: 9, message: "FULayout can be replaced with SwiftUI Layout equivalent. For example: HFlow -> HFlowLayout")
    @available(tvOS, introduced: 14, deprecated: 16, message: "FULayout can be replaced with SwiftUI Layout equivalent. For example: HFlow -> HFlowLayout")
    @available(visionOS, introduced: 1, deprecated: 1, message: "FULayout can be replaced with SwiftUI Layout equivalent. For example: HFlow -> HFlowLayout")
    @preconcurrency @MainActor
    func forEach<Data: RandomAccessCollection, Content: View>(_ data: Data, content: @escaping (Data.Element) -> Content) -> some View where Data.Element: Identifiable, Data.Index == Int {
        FULayoutEach(data, layout: self, content: content)
    }
}

@available(iOS, introduced: 14, deprecated: 16)
@available(macOS, introduced: 11, deprecated: 13)
@available(watchOS, introduced: 7, deprecated: 9)
@available(tvOS, introduced: 14, deprecated: 16)
@available(visionOS, introduced: 1, deprecated: 1)
fileprivate struct FULayoutEach<Data: RandomAccessCollection, Content: View, L: FULayout>: View where Data.Element: Identifiable, Data.Index == Int {
    let data: Array<(Data.Element, Int)>
    let layout: L
    let content: (Data.Element) -> Content
    
    @State private var contentOffsets: [Int: CGPoint] = [:]
    @State private var frameSize: CGSize? = nil
    
    init(_ data: Data, layout: L, content: @escaping (Data.Element) -> Content) {
        self.data = Array(zip(data, data.indices))
        self.layout = layout
        self.content = content
    }
    
    var defaultOffset: CGPoint {
        contentOffsets.first?.value ?? .zero
    }
    
    var body: some View {
        FULayoutRootView(layout, contentOffsets: $contentOffsets, frameSize: $frameSize) {
            ForEach(data, id: \.0.id) { (item, index) in
                FULayoutChildView(layout: layout, index: index, contentOffset: contentOffsets[index], defaultOffset: defaultOffset, content: content(item))
            }
        }
    }
}
