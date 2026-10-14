//
//  SystemToolbarVerticalGeometry.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-25.
//

import SwiftUI

/// The system's vertical toolbar, and the part of it the menu can use, measured with `reservedRegions`. ``TabMenuVerticalBarLayout`` places the menu in it.
@available(iOS 16, *)
struct SystemToolbarVerticalGeometry: Equatable, Sendable {
    /// The width of the system's vertical toolbar (measured on the iPhone Duo).
    static let defaultWidth: CGFloat = 84

    /// The edge the toolbar is on, measured with the rest of the toolbar. The environment's edge and the safe area can arrive a layout pass apart, so the menu draws on this edge rather than the environment's.
    let edge: HorizontalEdge
    let width: CGFloat
    /// How far the part of the toolbar the menu can use is from the window's top edge: below a camera at the top, or below the hinge.
    let topPadding: CGFloat
    /// How far the part of the toolbar the menu can use is from the window's bottom edge: above a camera at the bottom, or above the hinge. 0 when nothing is below it.
    let bottomPadding: CGFloat
    /// How far the content moves over for a vertical toolbar the system names without a safe area for it, or 0 when the safe area already covers it.
    let reservedWidth: CGFloat
}

@available(iOS 16, *)
extension SystemToolbarVerticalGeometry {
    /// Measures the system's vertical toolbar, from geometry expressed in the content's layout-relative coordinate space, or nil when there's no vertical toolbar or it's mid-change.
    init?(
        edge: HorizontalEdge?,
        contentSize: CGSize,
        safeAreaInsets: EdgeInsets,
        reservedFrames: [CGRect]
    ) {
        guard let edge else { return nil }

        let edgeInset = edge == .leading ? safeAreaInsets.leading : safeAreaInsets.trailing
        let oppositeInset = edge == .leading ? safeAreaInsets.trailing : safeAreaInsets.leading
        /// The width the menu reserves for the toolbar itself, by moving the content over.
        let reservedWidth: CGFloat
        let width: CGFloat
        if edgeInset > 0 {
            reservedWidth = 0
            width = edgeInset
        } else if oppositeInset == 0, safeAreaInsets.top == 0 {
            /// The iPhone Duo's left split window names a leading vertical toolbar but gets no safe area for it, and none on its other sides apart from the bottom (measured, iOS 27.1). The menu reserves the toolbar there.
            reservedWidth = SystemToolbarVerticalGeometry.defaultWidth
            width = SystemToolbarVerticalGeometry.defaultWidth
        } else {
            /// The environment can name a vertical toolbar one layout pass before the safe area moves to it. Mid-turn the inset is still on the other side, and mid-unfold the top inset is still there (measured on the iPhone Duo).
            return nil
        }

        /// The toolbar runs the window's full height, beside the content, or inside its edge when the menu reserves it.
        let minX = switch (edge, reservedWidth > 0) {
        case (.leading, false): -width
        case (.leading, true): CGFloat.zero
        case (.trailing, false): contentSize.width
        case (.trailing, true): contentSize.width - width
        }
        let maxX = minX + width
        let windowTop = -safeAreaInsets.top
        let windowBottom = contentSize.height + safeAreaInsets.bottom
        /// Spans are found above the grouped menu's bottom margin, so a region inside the margin doesn't leave a sliver of a span below it.
        let spanBottom = max(windowTop, windowBottom - TabMenuVerticalBarLayout.bottomMargin)

        let freeSpans = reservedFrames
            .map(\.standardized)
            .filter { $0.maxX > minX && $0.minX < maxX }
            .reduce([windowTop..<spanBottom]) { spans, frame in
                spans.flatMap { $0.subtracting(frame.minY..<frame.maxY) }
            }

        /// The menu never leaves the toolbar, and always sits in its lowest span, like the system's tab bar: below the hinge, and above a camera at the bottom.
        let span = freeSpans.last ?? windowTop..<spanBottom

        self.init(
            edge: edge,
            width: width,
            topPadding: span.lowerBound - windowTop,
            /// A span that reaches the margin has nothing below it, so an equal menu can run to the window's bottom edge.
            bottomPadding: span.upperBound < spanBottom ? windowBottom - span.upperBound : 0,
            reservedWidth: reservedWidth
        )
    }
}
