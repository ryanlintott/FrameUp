//
//  FULayout+forEach.swift
//  FrameUpExample
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
    func forEach<Data: RandomAccessCollection, Content: View>(_ data: Data, content: @escaping (Data.Element) -> Content) -> some View where Data.Element: Identifiable, Data.Index == Int {
        FULayoutEach(data, layout: self, content: content)
    }
}

fileprivate struct FULayoutEach<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable, Data.Index == Int {
    let data: Array<(Data.Element, Int)>
    let layout: AnyFULayout
    let content: (Data.Element) -> Content
    
    @State private var contentOffsets: [Int: CGPoint] = [:]
    @State private var frameSize: CGSize? = nil
    
    init(_ data: Data, layout: AnyFULayout, content: @escaping (Data.Element) -> Content) {
        self.data = Array(zip(data, data.indices))
        self.layout = layout
        self.content = content
    }
    
    init<L: FULayout>(_ data: Data, layout: L, content: @escaping (Data.Element) -> Content) {
        self = .init(data, layout: AnyFULayout(layout), content: content)
    }
    
    var body: some View {
        AnyFULayoutRootView(layout, contentOffsets: $contentOffsets, frameSize: $frameSize) {
            ForEach(data, id: \.0.id) { (item, index) in
                AnyFULayoutChildView(layout: layout, index: index, contentOffsets: contentOffsets, content: content(item))
            }
        }
    }
}
