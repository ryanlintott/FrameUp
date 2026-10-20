//
//  SystemBarGeometry.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-16.
//

#if os(iOS)
import SwiftUI

/// Where the system puts its tab bar, in the frame of the view that reads it, even inside an `AutoRotatingView`.
///
/// It's there to help an app place a bar of its own where the system's would be. Measure it once with `measuresSystemBarGeometry()` at the root of a scene, outside any rotation, and read it anywhere inside from ``SwiftUICore/EnvironmentValues/systemBarGeometry``. Every `AutoRotatingView` turns it for its content, the same way it turns the safe area, so a view inside a turned frame sees the bar on the edge of its own frame that the bar is really on.
///
///     ContentView()
///         .measuresSystemBarGeometry()
///
///     // Inside, at any depth:
///     @Environment(\.systemBarGeometry) var systemBar
///
/// The values describe the container: the window outside any rotation, and inside an `AutoRotatingView` the turned frame it fills. Edges are layout-relative, like SwiftUI's own.
public struct SystemBarGeometry: Equatable, Sendable {
    /// The kind of bar the system uses.
    public enum Kind: Hashable, Sendable {
        /// A bar along the bottom. It isn't measured: it's the system's usual 50 points above the bottom safe area.
        case bottom
        /// The system's vertical toolbar, such as the iPhone Duo's 84 point column, measured from `toolbarVerticalEdge`, the safe area and the reserved regions.
        case verticalToolbar
    }

    /// The kind of bar.
    public let kind: Kind
    /// The edge of the container the bar is on, layout-relative.
    public let edge: Edge
    /// How deep the bar is from that edge: 50 points plus the bottom safe area along the bottom, and the toolbar's width for a vertical toolbar.
    public let depth: CGFloat
    /// How far the part of the bar the system leaves free for its items is from the bar's start: its leading end along a top or bottom edge, and its top end along a leading or trailing edge. It's clear of the camera, the status items and the hinge.
    public let usableStart: CGFloat
    /// How far the free part of the bar is from the bar's other end: its trailing end along a top or bottom edge, and its bottom end along a leading or trailing edge.
    public let usableEnd: CGFloat
    /// The depth an app has to reserve itself, because the system names the bar without giving it a safe area, as in the iPhone Duo's left split window. 0 where the safe area already covers the bar.
    public let reservedDepth: CGFloat
}

/// A system bar in physical terms, so it can be turned with the content of an `AutoRotatingView` like its safe area.
internal struct SystemBar: Equatable, Sendable {
    let kind: SystemBarGeometry.Kind
    let physicalEdge: PhysicalEdge
    let depth: CGFloat
    /// How far the free part of the bar is from the end of the bar reached first going clockwise round the container: the left end of a top bar, the top of a right one, the right end of a bottom one, and the bottom of a left one.
    let clockwiseStart: CGFloat
    /// How far the free part of the bar is from its other end.
    let clockwiseEnd: CGFloat
    let reservedDepth: CGFloat
    /// The container the bar is on the edge of, layout-relative, in the nearest ``SystemBarContainerSpace``: the window at the root, and the turned frame inside an `AutoRotatingView`.
    var containerFrame: CGRect = .zero

    /// The bar as seen from inside a view turned by an angle, matched to the nearest quarter turn. Like the safe area's insets, an edge takes the bar on the edge a quarter turn behind it for each quarter turn clockwise. Turning keeps the clockwise order, so the ends keep their names.
    /// - Parameters:
    ///   - angle: The turn of the view the bar is seen from.
    ///   - container: That view's frame, the container the turned bar is described in.
    func rotated(by angle: Angle, container: CGRect) -> SystemBar {
        let physicalEdge = self.physicalEdge.rotated(quarterTurns: -angle.quarterTurns)
        return SystemBar(kind: kind, physicalEdge: physicalEdge, depth: depth, clockwiseStart: clockwiseStart, clockwiseEnd: clockwiseEnd, reservedDepth: reservedDepth, containerFrame: container)
    }

    /// The bar with layout-relative names.
    func geometry(for layoutDirection: LayoutDirection) -> SystemBarGeometry {
        let isLeftToRight = layoutDirection == .leftToRight
        /// Whether the bar's start, its leading or top end, is the end reached first going clockwise.
        let startsClockwise: Bool
        let edge: Edge
        switch physicalEdge {
        case .top:
            edge = .top
            startsClockwise = isLeftToRight
        case .bottom:
            edge = .bottom
            startsClockwise = !isLeftToRight
        case .right:
            edge = isLeftToRight ? .trailing : .leading
            startsClockwise = true
        case .left:
            edge = isLeftToRight ? .leading : .trailing
            startsClockwise = false
        }
        return SystemBarGeometry(
            kind: kind,
            edge: edge,
            depth: depth,
            usableStart: startsClockwise ? clockwiseStart : clockwiseEnd,
            usableEnd: startsClockwise ? clockwiseEnd : clockwiseStart,
            reservedDepth: reservedDepth
        )
    }
}

extension SystemBar {
    /// The depth of the system's bar along the bottom, above the bottom safe area.
    static let bottomBarHeight: CGFloat = 50

    /// Measures the system's bar from a view that fills the window, or nil when a vertical toolbar is mid-change.
    /// - Parameters:
    ///   - toolbarEdge: The edge of the system's vertical toolbar, from `toolbarVerticalEdge`, or nil when there's none.
    ///   - contentSize: The view's size, inside its safe area.
    ///   - safeAreaInsets: The view's safe area, layout-relative.
    ///   - reservedFrames: The reserved regions' frames, in the view's layout-relative space.
    ///   - layoutDirection: The view's layout direction.
    init?(toolbarEdge: HorizontalEdge?, contentSize: CGSize, safeAreaInsets: EdgeInsets, reservedFrames: [CGRect], layoutDirection: LayoutDirection) {
        let isLeftToRight = layoutDirection == .leftToRight
        guard let toolbarEdge else {
            let insets = PhysicalEdgeInsets(safeAreaInsets, layoutDirection: layoutDirection)
            /// Read clockwise along the bottom, from right to left.
            self.init(kind: .bottom, physicalEdge: .bottom, depth: Self.bottomBarHeight + insets.bottom, clockwiseStart: insets.right, clockwiseEnd: insets.left, reservedDepth: 0, containerFrame: Self.window(contentSize: contentSize, safeAreaInsets: safeAreaInsets))
            return
        }
        guard let toolbar = SystemToolbarVerticalGeometry(edge: toolbarEdge, contentSize: contentSize, safeAreaInsets: safeAreaInsets, reservedFrames: reservedFrames) else { return nil }
        let physicalEdge: PhysicalEdge = (toolbarEdge == .leading) == isLeftToRight ? .left : .right
        /// Read clockwise, a right toolbar runs top to bottom and a left one bottom to top.
        self.init(
            kind: .verticalToolbar,
            physicalEdge: physicalEdge,
            depth: toolbar.width,
            clockwiseStart: physicalEdge == .right ? toolbar.topPadding : toolbar.bottomPadding,
            clockwiseEnd: physicalEdge == .right ? toolbar.bottomPadding : toolbar.topPadding,
            reservedDepth: toolbar.reservedWidth,
            containerFrame: Self.window(contentSize: contentSize, safeAreaInsets: safeAreaInsets)
        )
    }

    /// The window around a view that fills it, in the view's own layout-relative space.
    static func window(contentSize: CGSize, safeAreaInsets: EdgeInsets) -> CGRect {
        CGRect(x: -safeAreaInsets.leading, y: -safeAreaInsets.top, width: contentSize.width + safeAreaInsets.leading + safeAreaInsets.trailing, height: contentSize.height + safeAreaInsets.top + safeAreaInsets.bottom)
    }
}

/// The coordinate space the system's bar is described in: the view `measuresSystemBarGeometry()` measures, and each `AutoRotatingView`'s turned frame.
internal struct SystemBarContainerSpace: Hashable {}

private struct SystemBarKey: EnvironmentKey {
    static let defaultValue: SystemBar? = nil
}

internal extension EnvironmentValues {
    /// The system's bar in physical terms, turned for the content of every enclosing `AutoRotatingView`.
    var fuSystemBar: SystemBar? {
        get { self[SystemBarKey.self] }
        set { self[SystemBarKey.self] = newValue }
    }
}

public extension EnvironmentValues {
    /// Where the system puts its tab bar, in this view's container, or nil where nothing measures it with `measuresSystemBarGeometry()`.
    ///
    /// Inside an `AutoRotatingView` it's turned with the content, so its edge is the edge of the turned frame the bar is really on.
    var systemBarGeometry: SystemBarGeometry? {
        fuSystemBar?.geometry(for: layoutDirection)
    }
}
#endif
