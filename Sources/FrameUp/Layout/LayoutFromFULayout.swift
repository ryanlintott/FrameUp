//
//  LayoutFromFULayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2023-05-12.
//

import SwiftUI

/// A SwiftUI `Layout` that is based on a FrameUp ``FULayout``
///
/// `sizeThatFits()` and `placeSubviews()` are generated automatically based on an associated ``FULayout``
@available(iOS 16, macOS 13, watchOS 9, tvOS 16, *)
public protocol LayoutFromFULayout: Layout {
    associatedtype AssociatedFULayout: FULayout
    
    /// The function that generates the associated ``FULayout``
    ///
    /// `sizeThatFits()` and `placeSubviews()` are generated automatically based on this ``FULayout``
    /// - Parameter maxSize: The maximum size available for the layout.
    /// - Returns: The associated FULayout initialized with the provied max size.
    func fuLayout(maxSize: CGSize) -> AssociatedFULayout
    
    /// The size used in place of any unspecified dimension in a proposed size.
    ///
    /// An unspecified dimension means the layout is being asked for its ideal size in that axis. Use `.infinity` for any axis where the associated ``FULayout`` should lay all views out in a single row or column, and a finite value for any axis where an infinite max size would produce infinite offsets.
    var sizeReplacingUnspecifiedDimensions: CGSize { get }
}

@available(iOS 16, macOS 13, watchOS 9, tvOS 16, *)
extension LayoutFromFULayout {
    /// The size used in place of any unspecified dimension in a proposed size.
    ///
    /// Matches the SwiftUI default of 10 by 10.
    public var sizeReplacingUnspecifiedDimensions: CGSize {
        ProposedViewSize.unspecified.replacingUnspecifiedDimensions()
    }
    
    /// Generates a dictionary of view sizes keyed by their index from the subview dimensions in the proposed view size.
    /// - Parameters:
    ///   - subviews: A collection of proxies for the subviews of a layout view.
    ///   - proposal: A proposal for the size of a view.
    /// - Returns: A dictionary of view sizes keyed by their index from the subview dimensions in the proposed view size.
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
        let fuLayout = fuLayout(maxSize: proposal.replacingUnspecifiedDimensions(by: sizeReplacingUnspecifiedDimensions))
        return fuLayout.rect(contentOffsets: fuLayout.contentOffsets(sizes: sizes), sizes: sizes).size
    }
    
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = sizes(for: subviews, proposal: proposal)
        let fuLayout = fuLayout(maxSize: bounds.size)
        let offsets = fuLayout.contentOffsets(sizes: sizes)
        for (index, subview) in subviews.enumerated() {
            if let offset = offsets[index] {
                let globalOffset = CGPoint(x: offset.x + bounds.origin.x, y: offset.y + bounds.origin.y)
                subview.place(at: globalOffset, proposal: proposal)
            }
        }
    }
}
