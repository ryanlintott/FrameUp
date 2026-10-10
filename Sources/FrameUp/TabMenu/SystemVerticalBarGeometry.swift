//
//  SystemVerticalBarGeometry.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-25.
//

import SwiftUI

/// Where a vertical tab menu goes in the system's vertical bar.
@available(iOS 16, *)
struct SystemVerticalBarGeometry: Equatable, Sendable {
    /// The system's natural item height, and the horizontal menu's height.
    static let itemHeight: CGFloat = 50
    /// The minimum tap target, below which the menu stops centring its items where the system centres its buttons. Items in a short span can still be squeezed shorter than this.
    static let minimumItemHeight: CGFloat = 44
    /// How far the system keeps its vertical tab bar from the window's bottom edge and from the side it's on (measured on the iPhone Duo).
    static let systemBarMargin: CGFloat = 24
    /// How far the centre of the system's vertical tab bar is from the window's side: its margin plus half its 48 point width.
    static let centreInset: CGFloat = 24 + 48 / 2
    /// The width of the system's vertical column (measured on the iPhone Duo).
    static let columnWidth: CGFloat = 84

    /// The edge the column is on, from the same measurement as the rest of the geometry. The environment's edge and the safe area can arrive a layout pass apart, so the menu draws on this edge rather than the environment's.
    let edge: HorizontalEdge
    let width: CGFloat
    let horizontalEdgePadding: CGFloat
    let itemHeight: CGFloat
    let height: CGFloat
    let bottomPadding: CGFloat
    /// How far the content moves over for a column the system names without a safe area for it, or 0 when the safe area already covers it.
    let reservedWidth: CGFloat
}

@available(iOS 16, *)
extension SystemVerticalBarGeometry {
    /// Places the menu in the system's vertical column, from geometry expressed in the content's layout-relative coordinate space, or nil when there's no column or it's mid-change.
    init?(
        edge: HorizontalEdge?,
        contentSize: CGSize,
        safeAreaInsets: EdgeInsets,
        reservedFrames: [CGRect],
        itemCount: Int
    ) {
        guard let edge, itemCount > 0 else { return nil }

        let edgeInset = edge == .leading ? safeAreaInsets.leading : safeAreaInsets.trailing
        let oppositeInset = edge == .leading ? safeAreaInsets.trailing : safeAreaInsets.leading
        /// The width the menu reserves for the column itself, by moving the content over.
        let reservedWidth: CGFloat
        let columnWidth: CGFloat
        if edgeInset > 0 {
            reservedWidth = 0
            columnWidth = edgeInset
        } else if oppositeInset == 0, safeAreaInsets.top == 0 {
            /// The iPhone Duo's left split window names a leading column but gets no safe area for it, and none on its other sides apart from the bottom (measured, iOS 27.1). The menu reserves the column there.
            reservedWidth = SystemVerticalBarGeometry.columnWidth
            columnWidth = SystemVerticalBarGeometry.columnWidth
        } else {
            /// The environment can name a column one layout pass before the safe area moves to it. Mid-turn the inset is still on the other side, and mid-unfold the top inset is still there (measured on the iPhone Duo).
            return nil
        }

        /// The column runs the window's full height, beside the content, or inside its edge when the menu reserves it.
        let columnMinX = switch (edge, reservedWidth > 0) {
        case (.leading, false): -columnWidth
        case (.leading, true): CGFloat.zero
        case (.trailing, false): contentSize.width
        case (.trailing, true): contentSize.width - columnWidth
        }
        let columnMaxX = columnMinX + columnWidth
        let windowTop = -safeAreaInsets.top
        let windowBottom = contentSize.height + safeAreaInsets.bottom
        let menuBottom = max(windowTop, windowBottom - SystemVerticalBarGeometry.systemBarMargin)

        let freeSpans = reservedFrames
            .map(\.standardized)
            .filter { $0.maxX > columnMinX && $0.minX < columnMaxX }
            .reduce([windowTop..<menuBottom]) { spans, frame in
                spans.flatMap { $0.subtracting(frame.minY..<frame.maxY) }
            }

        /// The menu never leaves the column, and always sits in its lowest span, like the system's tab bar: below the hinge, and above a camera at the bottom. Where that span is short, the items squeeze to fit.
        let span = freeSpans.last ?? windowTop..<menuBottom

        let itemHeight = min(SystemVerticalBarGeometry.itemHeight, (span.upperBound - span.lowerBound) / CGFloat(itemCount))

        /// Centre the items where the system centres its buttons, if the column is wide enough to keep them tappable.
        let centredWidth = 2 * (columnWidth - SystemVerticalBarGeometry.centreInset)
        let menuWidth = centredWidth >= SystemVerticalBarGeometry.minimumItemHeight
            ? min(columnWidth, centredWidth)
            : columnWidth

        self.init(
            edge: edge,
            width: menuWidth,
            horizontalEdgePadding: columnWidth - menuWidth,
            itemHeight: itemHeight,
            height: itemHeight * CGFloat(itemCount),
            bottomPadding: windowBottom - span.upperBound,
            reservedWidth: reservedWidth
        )
    }
}
