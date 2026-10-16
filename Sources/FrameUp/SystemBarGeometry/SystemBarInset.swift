//
//  SystemBarInset.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-16.
//

#if os(iOS)
import SwiftUI

public extension View {
    /// Draws a view where the system's bar is, and insets this view's content by however much of the bar overlaps it.
    ///
    /// The bar comes from ``SwiftUICore/EnvironmentValues/systemBarGeometry``, so it needs `measuresSystemBarGeometry()` further out, and inside an `AutoRotatingView` it's on the edge of the turned frame the system's bar is really on. Without a measurement this does nothing.
    ///
    ///     ContentView()
    ///         .systemBarInset { bar in
    ///             MyTabBar()
    ///                 .padding(.leading, bar.usableStart)
    ///                 .padding(.trailing, bar.usableEnd)
    ///         }
    ///
    /// The bar view fills the whole bar, from the container's edge to the bar's depth, so a background drawn in it covers the bar. Keep its items inside the usable part with the geometry's `usableStart` and `usableEnd`, and clear of the safe area the bar includes, such as the Home indicator's below a bar along the bottom.
    ///
    /// The bar is drawn where the system's bar is, even past this view's frame. This view's content is inset only by the part of the bar inside its safe area: all of a bar along the bottom, none of a vertical toolbar the safe area already leaves out, and the whole toolbar where the system gives it no safe area, as in the iPhone Duo's left split window.
    /// - Parameter bar: The view to draw in the bar, built from the bar's geometry.
    /// - Returns: A view with the bar drawn where the system's bar is.
    func systemBarInset<Bar: View>(@ViewBuilder bar: @escaping (SystemBarGeometry) -> Bar) -> some View {
        modifier(SystemBarInset(bar: bar))
    }
}

/// Where a view's system bar goes, and how much it insets the view's content.
internal struct SystemBarPlacement: Equatable {
    /// The bar's frame, relative to the view's own frame.
    let barFrame: CGRect
    /// How far the bar reaches into the view's safe area on each edge.
    let insets: EdgeInsets

    /// - Parameters:
    ///   - bar: The bar, layout-relative.
    ///   - container: The container the bar is on the edge of, in the container space.
    ///   - viewFrame: The view's frame, in the container space.
    ///   - safeAreaInsets: The view's safe area.
    init(bar: SystemBarGeometry, container: CGRect, viewFrame: CGRect, safeAreaInsets: EdgeInsets) {
        let barFrame: CGRect = switch bar.edge {
        case .top: CGRect(x: container.minX, y: container.minY, width: container.width, height: bar.depth)
        case .bottom: CGRect(x: container.minX, y: container.maxY - bar.depth, width: container.width, height: bar.depth)
        case .leading: CGRect(x: container.minX, y: container.minY, width: bar.depth, height: container.height)
        case .trailing: CGRect(x: container.maxX - bar.depth, y: container.minY, width: bar.depth, height: container.height)
        }
        let safeFrame = CGRect(
            x: viewFrame.minX + safeAreaInsets.leading,
            y: viewFrame.minY + safeAreaInsets.top,
            width: max(0, viewFrame.width - safeAreaInsets.leading - safeAreaInsets.trailing),
            height: max(0, viewFrame.height - safeAreaInsets.top - safeAreaInsets.bottom)
        )
        /// How far the bar reaches into the safe frame from one of its edges, within the safe frame.
        func overlap(_ depth: CGFloat, limit: CGFloat) -> CGFloat {
            min(max(0, depth), limit)
        }
        var insets = EdgeInsets()
        switch bar.edge {
        case .top: insets.top = overlap(barFrame.maxY - safeFrame.minY, limit: safeFrame.height)
        case .bottom: insets.bottom = overlap(safeFrame.maxY - barFrame.minY, limit: safeFrame.height)
        case .leading: insets.leading = overlap(barFrame.maxX - safeFrame.minX, limit: safeFrame.width)
        case .trailing: insets.trailing = overlap(safeFrame.maxX - barFrame.minX, limit: safeFrame.width)
        }
        self.barFrame = barFrame.offsetBy(dx: -viewFrame.minX, dy: -viewFrame.minY)
        self.insets = insets
    }
}

private struct SystemBarInset<Bar: View>: ViewModifier {
    let bar: (SystemBarGeometry) -> Bar
    @Environment(\.fuSystemBar) private var systemBar
    /// The turned frame's size at this step of a turn, while it animates.
    @Environment(\.fuAnimatedFrameSize) private var animatedFrameSize
    @Environment(\.layoutDirection) private var layoutDirection
    /// The view's frame in the container space and its safe area, measured outside the inset this adds, so the inset doesn't feed back into the measurement.
    @State private var measurement: Measurement? = nil

    struct Measurement: Equatable {
        let frame: CGRect
        let safeAreaInsets: EdgeInsets
    }

    func body(content: Content) -> some View {
        let geometry = systemBar?.geometry(for: layoutDirection)
        let placement: SystemBarPlacement? = if let systemBar, let geometry, let measurement {
            /// Through a turn the container changes shape step by step, so the bar follows its edge rather than jumping to where the edge will be.
            SystemBarPlacement(bar: geometry, container: CGRect(origin: systemBar.containerFrame.origin, size: animatedFrameSize ?? systemBar.containerFrame.size), viewFrame: measurement.frame, safeAreaInsets: measurement.safeAreaInsets)
        } else {
            nil
        }
        let insets = placement?.insets ?? EdgeInsets()
        content
            .safeAreaInset(edge: .top, spacing: 0) { Color.clear.frame(height: insets.top) }
            .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: insets.bottom) }
            .safeAreaInset(edge: .leading, spacing: 0) { Color.clear.frame(width: insets.leading) }
            .safeAreaInset(edge: .trailing, spacing: 0) { Color.clear.frame(width: insets.trailing) }
            .overlay(alignment: .topLeading) {
                if let placement, let geometry {
                    bar(geometry)
                        .frame(width: placement.barFrame.width, height: placement.barFrame.height)
                        .offset(x: placement.barFrame.minX, y: placement.barFrame.minY)
                }
            }
            .background(
                GeometryReader { proxy in
                    let newMeasurement = Measurement(frame: proxy.frame(in: .named(SystemBarContainerSpace())), safeAreaInsets: proxy.safeAreaInsets)
                    Color.clear
                        .onAppear { measurement = newMeasurement }
                        .onChange(of: newMeasurement) { measurement = $0 }
                }
            )
    }
}
#endif
