//
//  MeasuresSystemBarGeometry.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-16.
//

#if os(iOS)
import SwiftUI

public extension View {
    /// Measures where the system puts its tab bar, and passes it to everything inside as ``SwiftUICore/EnvironmentValues/systemBarGeometry``.
    ///
    /// Apply it once to a view that fills the window, outside any `AutoRotatingView`, such as the root of a scene. Every `AutoRotatingView` inside turns the measurement for its content.
    ///
    ///     ContentView()
    ///         .measuresSystemBarGeometry()
    ///
    /// The system's vertical toolbar is measured from `toolbarVerticalEdge` and `reservedRegions`, which need iOS 27.1 and the iOS 27.1 SDK. Elsewhere the bar is along the bottom.
    /// - Returns: A view that measures the system's bar for the views inside it.
    func measuresSystemBarGeometry() -> some View {
        modifier(MeasuresSystemBarGeometry())
    }
}

private struct MeasuresSystemBarGeometry: ViewModifier {
    @Environment(\.toolbarVerticalEdgeIfAvailable) private var toolbarEdge
    @Environment(\.layoutDirection) private var layoutDirection
    /// The last good measurement. Mid-turn, SwiftUI can name a vertical toolbar a layout pass before the safe area moves to it, and the reserved regions can be stale for a few passes (measured on the iPhone Duo), so a pass with no answer keeps the last one.
    @State private var systemBar: SystemBar? = nil

    func body(content: Content) -> some View {
        content
            .environment(\.fuSystemBar, systemBar)
            .coordinateSpace(name: SystemBarContainerSpace())
            .background(
                GeometryReader { proxy in
                    let measurement = measure(proxy)
                    Color.clear
                        .onAppear { update(measurement) }
                        .onChange(of: measurement) { update($0) }
                }
            )
    }

    func update(_ measurement: SystemBar?) {
        if let measurement {
            systemBar = measurement
        }
    }

    func measure(_ proxy: GeometryProxy) -> SystemBar? {
        SystemBar(
            toolbarEdge: toolbarEdge,
            contentSize: proxy.size,
            safeAreaInsets: proxy.safeAreaInsets,
            reservedFrames: reservedFrames(proxy),
            layoutDirection: layoutDirection
        )
    }

    func reservedFrames(_ proxy: GeometryProxy) -> [CGRect] {
        /// `reservedRegions` arrived in the iOS 27.1 SDK, whose SwiftUICore is version 8.0.85.
        #if canImport(SwiftUICore, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            /// A region's frame already includes its margins (measured on the iPhone Duo). Regions outside the window are stale, left from a window that has just changed.
            let window = SystemBar.window(contentSize: proxy.size, safeAreaInsets: proxy.safeAreaInsets)
            return (proxy.reservedRegions(kind: .occlusion) + proxy.reservedRegions(kind: .division, options: .includeInactive))
                .map(\.frame)
                .filter { window.intersects($0) }
        }
        #endif
        return []
    }
}

#endif
