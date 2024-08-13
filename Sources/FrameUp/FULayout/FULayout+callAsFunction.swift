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
    @MainActor
    func callAsFunction<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        _FULayoutView(self, content: content)
    }
}

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


