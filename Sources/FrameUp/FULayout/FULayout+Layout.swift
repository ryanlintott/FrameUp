//
//  FULayout+Layout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-10-20.
//

import SwiftUI

/// Work in progress
@available(iOS 16, macOS 13, *)
internal extension FULayout where Self: Layout {
    func sizes(for subviews: Subviews, proposal: ProposedViewSize) -> [Int: CGSize] {
        subviews
            .map {
                let dims = $0.dimensions(in: proposal)
                return CGSize(width: dims.width, height: dims.height)
            }
            .enumerated()
            .reduce(into: [Int: CGSize]()) { partialResult, indexedSubview in
                partialResult[indexedSubview.offset] = indexedSubview.element
            }
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = sizes(for: subviews, proposal: proposal)
        return rect(contentOffsets: contentOffsets(sizes: sizes), sizes: sizes).size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = sizes(for: subviews, proposal: proposal)
        let offsets = contentOffsets(sizes: sizes)
        for (index, subview) in subviews.enumerated() {
            if let offset = offsets[index] {
                let globalOffset = CGPoint(x: offset.x + bounds.origin.x, y: offset.y + bounds.origin.y)
                subview.place(at: globalOffset, proposal: .unspecified)
            }
        }
    }
}
