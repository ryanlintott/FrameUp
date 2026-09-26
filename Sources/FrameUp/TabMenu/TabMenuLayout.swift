//
//  TabMenuLayout.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-09-25.
//

import SwiftUI

/// Where an automatically placed tab menu goes.
enum TabMenuLayout: Equatable, Sendable {
    /// The vertical column has not been measured, or is mid-change.
    case unmeasured
    /// A horizontal menu along the bottom.
    case horizontal
    case vertical(VerticalTabMenuGeometry)

    /// Calculates a placement from geometry expressed in the content's layout-relative coordinate space.
    init(
        edge: HorizontalEdge?,
        contentSize: CGSize,
        safeAreaInsets: EdgeInsets,
        reservedFrames: [CGRect],
        itemCount: Int
    ) {
        guard let edge, itemCount > 0 else {
            self = .horizontal
            return
        }

        let columnWidth = edge == .leading ? safeAreaInsets.leading : safeAreaInsets.trailing
        /// The environment can name a column one layout pass before the safe area moves to it.
        guard columnWidth > 0 else {
            self = .unmeasured
            return
        }

        /// The column runs the window's full height, beside the content.
        let columnMinX = edge == .leading ? -columnWidth : contentSize.width
        let columnMaxX = columnMinX + columnWidth
        let windowTop = -safeAreaInsets.top
        let windowBottom = contentSize.height + safeAreaInsets.bottom
        let menuBottom = windowBottom - VerticalTabMenuGeometry.systemBarMargin

        guard menuBottom > windowTop else {
            self = .horizontal
            return
        }

        let freeSpans = reservedFrames
            .map(\.standardized)
            .filter { $0.maxX > columnMinX && $0.minX < columnMaxX }
            .reduce([windowTop..<menuBottom]) { spans, frame in
                spans.flatMap { $0.subtracting(frame.minY..<frame.maxY) }
            }

        /// Use the lowest span with room for minimum-size tap targets.
        let minimumMenuHeight = CGFloat(itemCount) * VerticalTabMenuGeometry.minimumItemHeight
        guard
            columnWidth >= VerticalTabMenuGeometry.minimumItemHeight,
            let span = freeSpans.last(where: { $0.length >= minimumMenuHeight })
        else {
            self = .horizontal
            return
        }

        let itemHeight = min(VerticalTabMenuGeometry.itemHeight, span.length / CGFloat(itemCount))

        /// Centre the items where the system centres its buttons, if the column is wide enough to keep them tappable.
        let centredWidth = 2 * (columnWidth - VerticalTabMenuGeometry.centreInset)
        let menuWidth = centredWidth >= VerticalTabMenuGeometry.minimumItemHeight
            ? min(columnWidth, centredWidth)
            : columnWidth

        self = .vertical(
            VerticalTabMenuGeometry(
                width: menuWidth,
                horizontalEdgePadding: columnWidth - menuWidth,
                itemHeight: itemHeight,
                height: itemHeight * CGFloat(itemCount),
                bottomPadding: windowBottom - span.upperBound
            )
        )
    }
}

/// Where a vertical tab menu goes in the system's vertical bar.
struct VerticalTabMenuGeometry: Equatable, Sendable {
    /// The system's natural item height, and the horizontal menu's height.
    static let itemHeight: CGFloat = 50
    /// The smallest item height before the menu gives up on the column. The minimum tap target.
    static let minimumItemHeight: CGFloat = 44
    /// How far the system keeps its vertical tab bar from the window's bottom edge and from the side it's on (measured on the iPhone Duo).
    static let systemBarMargin: CGFloat = 24
    /// How far the centre of the system's vertical tab bar is from the window's side: its margin plus half its 48 point width.
    static let centreInset: CGFloat = 24 + 48 / 2

    let width: CGFloat
    let horizontalEdgePadding: CGFloat
    let itemHeight: CGFloat
    let height: CGFloat
    let bottomPadding: CGFloat
}

private extension Range where Bound == CGFloat {
    var length: CGFloat {
        upperBound - lowerBound
    }

    func subtracting(_ other: Range<CGFloat>) -> [Self] {
        guard other.upperBound > lowerBound, other.lowerBound < upperBound else {
            return [self]
        }

        var remaining: [Self] = []
        if other.lowerBound > lowerBound {
            remaining.append(lowerBound..<Swift.min(upperBound, other.lowerBound))
        }
        if other.upperBound < upperBound {
            remaining.append(Swift.max(lowerBound, other.upperBound)..<upperBound)
        }
        return remaining
    }
}
