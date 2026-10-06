//
//  View+onAvailableSizeChange.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-01.
//

import SwiftUI

/// A layout that takes the size of its first subview, and places its second subview at the full size offered to it, so that subview can measure space the first one doesn't use.
@available(iOS 16, macOS 13, watchOS 9, tvOS 16, *)
fileprivate struct AvailableSizeLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        subviews.first?.sizeThatFits(proposal) ?? .zero
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, proposal: ProposedViewSize(bounds.size))
        guard subviews.count > 1 else { return }
        /// This is the parent's final offer, not one of the trial sizes it may ask about first. Where it offers no size, or an infinite one, there is no space to measure beyond the view's own size.
        let available = CGSize(
            width: proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? bounds.width,
            height: proposal.height.flatMap { $0.isFinite ? $0 : nil } ?? bounds.height
        )
        subviews[1].place(at: bounds.origin, proposal: ProposedViewSize(available))
    }
}

internal extension View {
    /// Adds an action to perform when the size offered to the view by its parent changes, even when the view doesn't use all of it.
    ///
    /// The view's own size is unchanged. The space is measured by an invisible view that may extend beyond the view's bounds.
    /// - Parameter action: The action to perform when the available size changes. The action closure passes the new size as its parameter.
    /// - Returns: A view that performs the action when the available size changes.
    @available(iOS 16, macOS 13, watchOS 9, tvOS 16, *)
    func onAvailableSizeChange(_ action: @escaping (CGSize) -> Void) -> some View {
        AvailableSizeLayout {
            self
            Color.clear
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .onGeometryChange(for: CGSize.self) { proxy in
                    proxy.size
                } action: { newValue in
                    action(newValue)
                }
        }
    }
}
