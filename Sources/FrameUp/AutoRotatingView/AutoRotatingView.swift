//
//  AutoRotatingView.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2020-12-31.
//

import SwiftUI

#if os(iOS)
/// A view that rotates and resizes the content frame to match device orientation.
///
/// Content fills the available space, including the safe area, and the safe area is re-created inside the rotation. When the system turns the interface to an orientation the content doesn't allow, the content turns back as set by `counterRotation`.
///
/// An `AutoRotatingView` inside another turns relative to it, and all of them turn together on the outermost one's turn. On the inner screen of a foldable iPhone the content keeps to its allowed orientations, named as that screen names them.
public struct AutoRotatingView<Content: View>: View {
    @Environment(\.layoutDirection) private var layoutDirection

    private enum Mode {
        case allowed([FUInterfaceOrientation], counterRotation: FUCounterRotationStyle)
        case topEdges([FUInterfaceOrientation: Edge])
    }

    private let mode: Mode
    let isOn: Bool
    let animation: Animation?
    let content: (AutoRotatingGeometryProxy) -> Content

    /// A view that rotates and resizes the content frame to match device orientation.
    /// - Parameters:
    ///   - allowedOrientations: Set of allowed orientations for this view. Default is all.
    ///   - isOn: Toggles ability to rotate views.
    ///   - counterRotation: How the content looks still while the system turns the interface to an orientation the content doesn't allow. It has no effect when the content turns to a different orientation.
    ///   - animation: Animation for turns the content makes without the system, or nil for none. System turns use the system's timing.
    ///   - content: Content to be rotated to match a device orientations from an allowed orientation set.
    public init(_ allowedOrientations: [FUInterfaceOrientation] = FUInterfaceOrientation.allCases, isOn: Bool = true, counterRotation: FUCounterRotationStyle = .system, animation: Animation? = .easeInOut(duration: 0.3), @ViewBuilder content: () -> Content) {
        /// Built here so state the caller reads in it is tracked from the first update.
        let content = content()
        self.init(allowedOrientations, isOn: isOn, counterRotation: counterRotation, animation: animation, content: { _ in content })
    }

    /// A view that rotates and resizes the content frame to match device orientation, and gives its content the container geometry turned with it.
    ///
    /// The closure runs on every update, like a `GeometryReader`'s.
    /// - Parameters:
    ///   - allowedOrientations: Set of allowed orientations for this view. Default is all.
    ///   - isOn: Toggles ability to rotate views.
    ///   - counterRotation: How the content looks still while the system turns the interface to an orientation the content doesn't allow. It has no effect when the content turns to a different orientation.
    ///   - animation: Animation for turns the content makes without the system, or nil for none. System turns use the system's timing.
    ///   - content: Content to be rotated, built from the container geometry. See ``AutoRotatingGeometryProxy``.
    public init(_ allowedOrientations: [FUInterfaceOrientation] = FUInterfaceOrientation.allCases, isOn: Bool = true, counterRotation: FUCounterRotationStyle = .system, animation: Animation? = .easeInOut(duration: 0.3), @ViewBuilder content: @escaping (AutoRotatingGeometryProxy) -> Content) {
        self.mode = .allowed(allowedOrientations, counterRotation: counterRotation)
        self.isOn = isOn
        self.animation = animation
        self.content = content
    }

    /// A view that holds a frame fixed to the device, and turns its content inside it so the content's top faces a chosen edge, as the user sees it, in each orientation.
    ///
    ///     AutoRotatingView(topEdges: [.portrait: .top, .landscapeRight: .leading, .landscapeLeft: .leading]) {
    ///         Cover()
    ///     }
    ///
    /// An orientation left out of the dictionary leaves the content where it is. When there's nowhere it is yet, such as on first appearing, the content takes the entry for the interface's orientation.
    /// - Parameters:
    ///   - topEdges: Where the content's top points, layout-relative, in each orientation of the device.
    ///   - isOn: Toggles ability to rotate views.
    ///   - animation: Animation for turns the content makes without the system, or nil for none. System turns use the system's timing.
    ///   - content: Content to turn, built from the container geometry. See ``AutoRotatingGeometryProxy``.
    @available(iOS 17, *)
    public init(topEdges: [FUInterfaceOrientation: Edge], isOn: Bool = true, animation: Animation? = .easeInOut(duration: 0.3), @ViewBuilder content: @escaping (AutoRotatingGeometryProxy) -> Content) {
        self.mode = .topEdges(topEdges)
        self.isOn = isOn
        self.animation = animation
        self.content = content
    }

    /// A view that holds a frame fixed to the device, and turns its content inside it so the content's top faces a chosen edge, as the user sees it, in each orientation.
    ///
    /// See `init(topEdges:isOn:animation:content:)`.
    @available(iOS 17, *)
    public init(topEdges: [FUInterfaceOrientation: Edge], isOn: Bool = true, animation: Animation? = .easeInOut(duration: 0.3), @ViewBuilder content: () -> Content) {
        /// Built here so state the caller reads in it is tracked from the first update.
        let content = content()
        self.init(topEdges: topEdges, isOn: isOn, animation: animation, content: { _ in content })
    }

    public var body: some View {
        switch mode {
        case let .allowed(allowedOrientations, counterRotation):
            AutoRotatingLayer(allowedOrientations, isOn: isOn, counterRotation: counterRotation, animation: animation, content: content)
        case let .topEdges(topEdges):
            if #available(iOS 17, *) {
                /// The outer layer's frame is fixed to the device.
                AutoRotatingLayer([.portrait], isOn: isOn, counterRotation: .hold, animation: animation) { _ in
                    AutoRotatingLayer(presenting: .contentOrientations(topEdges: topEdges, layoutDirection: layoutDirection), isOn: isOn, counterRotation: .hold, animation: animation, content: content)
                }
            }
        }
    }
}

internal extension Dictionary where Key == FUInterfaceOrientation, Value == FUInterfaceOrientation {
    /// The orientation content presents in each orientation of the device so its top faces the given edge as the user sees it.
    /// - Parameters:
    ///   - topEdges: Where the content's top points as the user sees it, layout-relative.
    ///   - layoutDirection: The layout direction the edges are named in.
    static func contentOrientations(topEdges: [FUInterfaceOrientation: Edge], layoutDirection: LayoutDirection) -> Self {
        Dictionary(uniqueKeysWithValues: topEdges.map { orientation, edge in
            (orientation, orientation.contentOrientation(topAt: PhysicalEdge(edge, layoutDirection: layoutDirection)))
        })
    }
}
#endif
