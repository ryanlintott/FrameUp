//
//  SwiftUIView.swift
//  
//
//  Created by Ryan Lintott on 2023-05-12.
//

import SwiftUI

/// A type of SwiftUI Layout that is based on an FULayout
///
/// `sizeThatFits()` and `placeSubviews()` are generated automatically based on an associated `FULayout`
@available(iOS 16, macOS 13, *)
public protocol LayoutFromFULayout: Layout {
    associatedtype AssociatedFULayout: FULayout
    
    /// The function that generates the associated FULayout
    ///
    /// `sizeThatFits()` and `placeSubviews()` are generated automatically based on this `FULayout`
    /// - Parameter maxSize: The maximum size available for the layout.
    /// - Returns: The associated FULayout initialized with the provied max size.
    func fuLayout(maxSize: CGSize) -> AssociatedFULayout
}

@available(iOS 16, macOS 13, *)
extension LayoutFromFULayout {
    public func sizes(for subviews: Subviews, proposal: ProposedViewSize) -> [Int: CGSize] {
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
    
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = sizes(for: subviews, proposal: proposal)
        let fuLayout = fuLayout(maxSize: proposal.replacingUnspecifiedDimensions())
        return fuLayout.rect(contentOffsets: fuLayout.contentOffsets(sizes: sizes), sizes: sizes).size
    }
    
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = sizes(for: subviews, proposal: proposal)
        let fuLayout = fuLayout(maxSize: bounds.size)
        let offsets = fuLayout.contentOffsets(sizes: sizes)
        for (index, subview) in subviews.enumerated() {
            if let offset = offsets[index] {
                let globalOffset = CGPoint(x: offset.x + bounds.origin.x, y: offset.y + bounds.origin.y)
                subview.place(at: globalOffset, proposal: .unspecified)
            }
        }
    }
}
