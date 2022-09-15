//
//  FULayoutRootAndChildView.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-18.
//

import SwiftUI

/// A preference key used for managing view sizes in a FrameUp layout view.
public struct FULayoutSizeKey: PreferenceKey {
    public typealias Value = [Int: CGSize]
    public static let defaultValue: [Int: CGSize] = [:]
    public static func reduce(value: inout Value, nextValue: () -> Value) {
        nextValue().forEach {
            value.updateValue($0.value, forKey: $0.key)
        }
    }
}

/// The root view used in `_FULayoutView` and `FULayoutEach`.
internal struct AnyFULayoutRootView<Content: View>: View {
    let layout: AnyFULayout
    @Binding var contentOffsets: [Int: CGPoint]
    @Binding var frameSize: CGSize?
    let content: Content
    
    var isInvisible: Bool { frameSize == nil || contentOffsets == [:] }

    init(_ layout: AnyFULayout, contentOffsets: Binding<[Int: CGPoint]>, frameSize: Binding<CGSize?>, content: () -> Content) {
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
            self.contentOffsets = layout.contentOffsets(sizes: $0)
            self.frameSize = layout.rect(contentOffsets: contentOffsets, sizes: $0).size
        }
        /// These modifiers are used to ensure initial content sizing uses an invisible view that won't effect the overall frame. Once the offset is known it will appear with the correct placement.
        .frame(width: isInvisible ? .zero : nil, height: isInvisible ? .zero : nil)
        .opacity(isInvisible ? 0 : 1)
        .id(isInvisible)
        .id(layout.id)
    }
}

/// The child view used in `_FULayoutView` and `FULayoutEach`.
internal struct AnyFULayoutChildView<Content: View>: View {
    let layout: AnyFULayout
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
            .id(layout.id)
    }
}
