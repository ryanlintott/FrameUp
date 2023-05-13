//
//  LayoutThatFits.swift
//  
//
//  Created by Ryan Lintott on 2022-06-09.
//

import SwiftUI

/// Creates a layout using the first layout that fits in the axes provided from the array of layout preferences.
@available(iOS 16, macOS 13, *)
public struct LayoutThatFits: Layout {
    public let axes: Axis.Set
    public let layoutPreferences: [AnyLayout]
    
    /// Creates a layout using the first layout that fits in the axes provided from the array of layout preferences.
    /// - Parameters:
    ///   - axes: Axes this content must fit in.
    ///   - layoutPreferences: Layout preferences from largest to smallest.
    public init(in axes: Axis.Set = [.horizontal, .vertical], _ layoutPreferences: [any Layout]) {
        self.axes = axes
        self.layoutPreferences = layoutPreferences.map { AnyLayout($0) }
    }
    
    public func layoutThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> AnyLayout? {
        layoutPreferences.first(where: { layout in
            var cache = layout.makeCache(subviews: subviews)
            let size = layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
            
            let widthFits = size.width <= (proposal.width ?? .infinity)
            let heightFits = size.height <= (proposal.height ?? .infinity)
            
            return (widthFits || !axes.contains(.horizontal)) && (heightFits || !axes.contains(.vertical))
        })
    }
    
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let layout = layoutThatFits(proposal: proposal, subviews: subviews, cache: &cache) ?? layoutPreferences.last else { return CGSize(width: 10, height: 10) }
        var cache = layout.makeCache(subviews: subviews)
        return layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
    }
    
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let layout = layoutThatFits(proposal: proposal, subviews: subviews, cache: &cache) ?? layoutPreferences.last else { return }
        var cache = layout.makeCache(subviews: subviews)
        layout.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
    }
}
