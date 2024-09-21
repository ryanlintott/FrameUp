//
//  FULayoutRootAndChildView.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-18.
//

import SwiftUI

/// The root view used in `_FULayoutView` and `FULayoutEach`.
@available(iOS, introduced: 14, deprecated: 16)
@available(macOS, introduced: 11, deprecated: 13)
@available(watchOS, introduced: 7, deprecated: 9)
@available(tvOS, introduced: 14, deprecated: 16)
@available(visionOS, introduced: 1, deprecated: 1)
internal struct FULayoutRootView<Content: View, L: FULayout>: View {
    let layout: L
    @Binding var contentOffsets: [Int: CGPoint]
    @Binding var frameSize: CGSize?
    let content: Content
    
    var isInvisible: Bool { frameSize == nil || contentOffsets == [:] }
    
    @State private var sizes: [Int: CGSize] = [:]

    init(_ layout: L, contentOffsets: Binding<[Int: CGPoint]>, frameSize: Binding<CGSize?>, content: () -> Content) {
        self.layout = layout
        self._contentOffsets = contentOffsets
        self._frameSize = frameSize
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            content
        }
        .frame(frameSize, alignment: .topLeading)
        .fixedSize()
        .onPreferenceChange(FULayoutSizeKey.self) {
            sizes = $0
        }
        /// These modifiers are used to ensure initial content sizing uses an invisible view that won't effect the overall frame. Once the offset is known it will appear with the correct placement.
        .frame(width: isInvisible ? .zero : nil, height: isInvisible ? .zero : nil)
        .opacity(isInvisible ? 0 : 1)
        .id(isInvisible)
        /// When either the size or the layout changes, run an update.
        .onChange(of: sizes) { newSizes in
            updateLayout(layout, sizes: newSizes)
        }
        .onChange(of: layout) { newLayout in
            updateLayout(newLayout, sizes: sizes)
        }
    }
    
    func updateLayout(_ layout: some FULayout, sizes: [Int: CGSize]) {
        contentOffsets = layout.contentOffsets(sizes: sizes)
        frameSize = layout.rect(contentOffsets: contentOffsets, sizes: sizes).size
    }
}

/// The child view used in `_FULayoutView` and `FULayoutEach`.
@available(iOS, introduced: 14, deprecated: 16)
@available(macOS, introduced: 11, deprecated: 13)
@available(watchOS, introduced: 7, deprecated: 9)
@available(tvOS, introduced: 14, deprecated: 16)
@available(visionOS, introduced: 1, deprecated: 1)
internal struct FULayoutChildView<Content: View, L: FULayout>: View {
    let layout: L
    let index: Int
    let contentOffset: CGPoint?
    /// Ensures content is placed inside the frame of existing content
    let defaultOffset: CGPoint
    let content: Content
    
    var isInvisible: Bool { contentOffset == nil }
    
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
                alignment: .topLeading
            )
            .alignmentGuide(.leading) { d in
                -(contentOffset ?? defaultOffset).x
            }
            .alignmentGuide(.top) { d in
                -(contentOffset ?? defaultOffset).y
            }
            /// These modifiers are used to ensure initial content sizing uses an invisible view that won't effect the overall frame. Once the offset is known it will appear with the correct placement.
            .opacity(isInvisible ? 0 : 1)
            .id(isInvisible)
            .accessibilityHidden(isInvisible)
    }
}
