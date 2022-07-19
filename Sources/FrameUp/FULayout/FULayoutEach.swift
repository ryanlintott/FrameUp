//
//  FULayoutEach.swift
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
        ZStack(alignment: layout.alignment) {
            ForEach(data, id: \.0.id) { (item, index) in
                AnyFULayoutChildView(layout: layout, index: index, contentOffsets: contentOffsets, content: content(item))
//                content(item)
//                    .overlay(
//                        GeometryReader { proxy in
//                            Color.clear
//                                .preference(key: LayoutSizeKey.self, value: [index: proxy.size])
//                        }
//                    )
//                    .fixedSize(
//                        horizontal: layout.fixedSize.contains(.horizontal),
//                        vertical: layout.fixedSize.contains(.vertical)
//                    )
//                    .frame(
//                        maxWidth: layout.maxItemWidth,
//                        maxHeight: layout.maxItemHeight,
//                        alignment: layout.itemAlignment
//                    )
//                    .alignmentGuide(layout.alignment.horizontal) { d in
//                        -(contentOffsets[index]?.x ?? .zero)
//                    }
//                    .alignmentGuide(layout.alignment.vertical) { d in
//                        -(contentOffsets[index]?.y ?? .zero)
//                    }
            }
        }
        .frame(frameSize, alignment: layout.alignment)
        .fixedSize()
        .onPreferenceChange(FULayoutSizeKey.self) {
            contentOffsets = layout.contentOffsets(sizes: $0)
            frameSize = layout.rect(contentOffsets: contentOffsets, sizes: $0).size
        }
        .id(layout.id)
//        .onChange(of: layout) { newValue in
//            contentOffsets = [:]
//            frameSize = nil
//        }
    }
}

/// This generalization doesn't work for some reason
struct AnyFULayoutRootView<Content: View>: View {
    let layout: AnyFULayout
    @Binding var contentOffsets: [Int: CGPoint]
    @Binding var frameSize: CGSize?
    let content: Content

    init(_ layout: AnyFULayout, contentOffsets: Binding<[Int: CGPoint]>, frameSize: Binding<CGSize?>, content: () -> Content) {
        self.layout = layout
        self._contentOffsets = contentOffsets
        self._frameSize = frameSize
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: layout.alignment) {
            content
        }
        .frame(frameSize, alignment: layout.alignment)
        .fixedSize()
        .onPreferenceChange(LayoutSizeKey.self) {
            self.contentOffsets = layout.contentOffsets(sizes: $0)
            self.frameSize = layout.rect(contentOffsets: contentOffsets, sizes: $0).size
        }
        .id(layout.id)
    }
}

struct AnyFULayoutChildView<Content: View>: View {
    let layout: AnyFULayout
    let index: Int
    let contentOffsets: [Int: CGPoint]
    let content: Content
    
    var body: some View {
        content
            .overlay(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: FULayoutSizeKey.self, value: [index: proxy.size])
                }
            )
            .fixedSize(
                horizontal: layout.fixedSize.contains(.horizontal),
                vertical: layout.fixedSize.contains(.vertical)
            )
            .frame(
                maxWidth: layout.maxItemWidth,
                maxHeight: layout.maxItemHeight,
                alignment: layout.itemAlignment
            )
            .alignmentGuide(layout.alignment.horizontal) { d in
                -(contentOffsets[index]?.x ?? .zero)
            }
            .alignmentGuide(layout.alignment.vertical) { d in
                -(contentOffsets[index]?.y ?? .zero)
            }
            .id(layout.id)
    }
}
