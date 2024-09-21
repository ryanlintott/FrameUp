//
//  FULayout+callAsFunction.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

public extension FULayout {
    /// Creates a view that arranges its children based on the parent FrameUp layout.
    /// - Parameter content: A closure view containing child views.
    /// - Returns: A view that arranges its children based on the parent FrameUp layout.
    @available(iOS, introduced: 14, deprecated: 16, message: "FULayout can be replaced with SwiftUI Layout equivalent. For example: HFlow -> HFlowLayout")
    @available(macOS, introduced: 11, deprecated: 13, message: "FULayout can be replaced with SwiftUI Layout equivalent. For example: HFlow -> HFlowLayout")
    @available(watchOS, introduced: 7, deprecated: 9, message: "FULayout can be replaced with SwiftUI Layout equivalent. For example: HFlow -> HFlowLayout")
    @available(tvOS, introduced: 14, deprecated: 16, message: "FULayout can be replaced with SwiftUI Layout equivalent. For example: HFlow -> HFlowLayout")
    @available(visionOS, introduced: 1, deprecated: 1, message: "FULayout can be replaced with SwiftUI Layout equivalent. For example: HFlow -> HFlowLayout")
    @preconcurrency @MainActor
    func callAsFunction<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        _FULayoutView(self, content: content)
    }
}

@available(iOS, introduced: 14, deprecated: 16)
@available(macOS, introduced: 11, deprecated: 13)
@available(watchOS, introduced: 7, deprecated: 9)
@available(tvOS, introduced: 14, deprecated: 16)
@available(visionOS, introduced: 1, deprecated: 1)
fileprivate struct _FULayoutView<Content: View, L: FULayout>: View {
    let layout: L
    let content: Content
    
    init(_ layout: L, @ViewBuilder content: () -> Content) {
        self.layout = layout
        self.content = content()
    }
    
    @State private var contentOffsets: [Int: CGPoint] = [:]
    @State private var frameSize: CGSize? = nil
    
    var body: some View {
        FULayoutRootView(layout, contentOffsets: $contentOffsets, frameSize: $frameSize) {
            _VariadicView.Tree(_VariadicFULayoutRoot(layout, contentOffsets: contentOffsets)) {
                content
            }
        }
    }
}

@available(iOS, introduced: 14, deprecated: 16)
@available(macOS, introduced: 11, deprecated: 13)
@available(watchOS, introduced: 7, deprecated: 9)
@available(tvOS, introduced: 14, deprecated: 16)
@available(visionOS, introduced: 1, deprecated: 1)
fileprivate struct _VariadicFULayoutRoot<L: FULayout>: _VariadicView_MultiViewRoot {
    let layout: L
    let contentOffsets: [Int: CGPoint]
    
    init(_ layout: L, contentOffsets: [Int : CGPoint]) {
        self.layout = layout
        self.contentOffsets = contentOffsets
    }
    
    var defaultOffset: CGPoint {
        contentOffsets.first?.value ?? .zero
    }
    
    @ViewBuilder
    func body(children: _VariadicView.Children) -> some View {
        ForEach(Array(zip(children, children.indices)), id: \.0.id) { (child, index) in
            FULayoutChildView(layout: layout, index: index, contentOffset: contentOffsets[index], defaultOffset: defaultOffset, content: child)
        }
    }
}
