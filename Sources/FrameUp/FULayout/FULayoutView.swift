//
//  File.swift
//
//
//  Created by Ryan Lintott on 2022-07-14.
//

import SwiftUI

public extension FULayout {
    func _view<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        _FULayoutView(self, content: content)
    }
}

fileprivate struct _FULayoutView<Content: View>: View {
    let layout: AnyFULayout
    let content: Content
    
    init<L: FULayout>(_ layout: L, @ViewBuilder content: () -> Content) {
        self.layout = AnyFULayout(layout)
        self.content = content()
    }
    
    @State private var contentOffsets: [Int: CGPoint] = [:]
    @State private var frameSize: CGSize? = nil
    
    var body: some View {
        ZStack(alignment: layout.alignment) {
            _VariadicView.Tree(_VariadicFULayoutRoot(layout, contentOffsets: contentOffsets)) {
                content
            }
        }
        .frame(frameSize, alignment: layout.alignment)
        .fixedSize()
        .onPreferenceChange(FULayoutSizeKey.self) {
            contentOffsets = layout.contentOffsets(sizes: $0)
            frameSize = layout.rect(contentOffsets: contentOffsets, sizes: $0).size
        }
        .id(layout.id)
    }
}

fileprivate struct _VariadicFULayoutRoot: _VariadicView_MultiViewRoot {
    let layout: AnyFULayout
    let contentOffsets: [Int: CGPoint]
    
    init(_ layout: AnyFULayout, contentOffsets: [Int : CGPoint]) {
        self.layout = layout
        self.contentOffsets = contentOffsets
    }
    
    
    @ViewBuilder
    func body(children: _VariadicView.Children) -> some View {
        ForEach(Array(zip(children, children.indices)), id: \.0.id) { (child, index) in
            AnyFULayoutChildView(layout: layout, index: index, contentOffsets: contentOffsets, content: child)
        }
    }
}
