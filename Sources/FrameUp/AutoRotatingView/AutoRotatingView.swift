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
/// Content is laid out in all the available space including any safe area around it, and a matching safe area is re-created. Content can either respect that safe area or ignore it with `ignoresSafeArea()`, and in both cases it turns around the centre of the safe area rather than drifting off the axis of rotation part way through the turn.
///
/// When the device turns to an orientation the app supports but the content doesn't, the system turns the interface, and the content turns back to keep its orientation. `systemRotation` sets how it moves during that turn: its orientation is locked but its position drifts with the system's animation (the default), or it's locked completely still (iOS 17 and later). See ``FUSystemRotationBehavior``. The system clips the window as it turns, so the corners of the screen go dark part way through a turn.
///
/// An `AutoRotatingView` inside another turns relative to it, so content that allows more orientations turns to stay upright on a frame that's held still.
///
/// On the inner screen of a foldable iPhone the system ignores an app's supported orientations and turns the interface to every orientation of the device. The content keeps to its allowed orientations there too, named as the inner screen's interface names them, so a portrait content stays taller than it is wide on either screen. When the device is folded or unfolded, the content takes the orientation it allows on the new screen without an animation: the device's, if it's allowed, or otherwise the one it's most likely held in, judged from how it was held on the old screen.
///
/// `init(topEdges:)` instead holds a frame fixed to the device and turns the content inside it, so the content's top faces a chosen edge in each orientation.
public struct AutoRotatingView<Content: View>: View {
    @Environment(\.layoutDirection) private var layoutDirection

    /// How the content turns.
    private enum Mode {
        /// The content turns to the device orientation, within these orientations.
        case allowed([FUInterfaceOrientation], systemRotation: FUSystemRotationBehavior)
        /// The frame is fixed to the device, and the content's top faces these edges, layout-relative, as the user sees them.
        case topEdges([FUInterfaceOrientation: Edge])
    }

    private let mode: Mode
    /// Toggle to turn this modifier on or off.
    let isOn: Bool
    /// Animation to use when the content turns on its own. When the system rotates the interface, the content always turns with the system's own animation.
    let animation: Animation?
    /// Content for the view, built from the container geometry that SwiftUI doesn't turn with it.
    let content: (AutoRotatingGeometryProxy) -> Content

    /// A view that rotates and resizes the content frame to match device orientation.
    ///
    /// View will take all available space, drawing into any safe area around it and re-creating that safe area inside the rotation.
    ///
    /// When the system rotates the interface, `animation` is ignored as the system rotates everything with its own animation. When the content turns on its own, such as when the device turns to an orientation the app doesn't support, it uses `animation`. Moving between the screens of a foldable iPhone is never animated.
    /// - Parameters:
    ///   - allowedOrientations: Set of allowed orientations for this view. Default is all.
    ///   - isOn: Toggles ability to rotate views.
    ///   - systemRotation: How the content moves while the system turns the interface to an orientation the content doesn't allow. Default is `.lockedOrientation`, where the system's animation carries the content and it keeps its orientation but not its place. `.locked` keeps it completely still (iOS 17 and later).
    ///   - animation: Animation to use when the content turns on its own, or nil for no animation. Default is the system's rotation animation, measured as 0.3 seconds ease in and out.
    ///   - content: Content to be rotated to match a device orientations from an allowed orientation set.
    public init(_ allowedOrientations: [FUInterfaceOrientation] = FUInterfaceOrientation.allCases, isOn: Bool = true, systemRotation: FUSystemRotationBehavior = .lockedOrientation, animation: Animation? = .easeInOut(duration: 0.3), @ViewBuilder content: () -> Content) {
        /// Built here rather than stored as a closure, so state the caller reads in it is tracked from the caller's first update.
        let content = content()
        self.init(allowedOrientations, isOn: isOn, systemRotation: systemRotation, animation: animation, content: { _ in content })
    }

    /// A view that rotates and resizes the content frame to match device orientation, and gives its content the container geometry that SwiftUI doesn't turn with it.
    ///
    /// SwiftUI doesn't turn the container's corners with a rotation, so inside the content its own `containerCornerInsets`, `containerCornerOffset` and `concentricCornerRadii` describe the unrotated container. The geometry has them turned with the content. Other geometry, such as size, safe area insets and reserved regions, is correct in a `GeometryReader` inside the content.
    ///
    ///     AutoRotatingView([.portrait]) { geometry in
    ///         Content()
    ///             .padding(.top, geometry.containerCornerInsets.topTrailing.height)
    ///     }
    ///
    /// The closure is called on every update of the view, like a `GeometryReader`'s. State the caller reads only inside a branch that depends on the geometry isn't tracked until that branch first runs, so it can be out of date the first time the branch appears. Read that state before the branch to avoid this.
    /// - Parameters:
    ///   - allowedOrientations: Set of allowed orientations for this view. Default is all.
    ///   - isOn: Toggles ability to rotate views.
    ///   - systemRotation: How the content moves while the system turns the interface to an orientation the content doesn't allow. Default is `.lockedOrientation`, where the system's animation carries the content and it keeps its orientation but not its place. `.locked` keeps it completely still (iOS 17 and later).
    ///   - animation: Animation to use when the content turns on its own, or nil for no animation. Default is the system's rotation animation, measured as 0.3 seconds ease in and out.
    ///   - content: Content to be rotated to match a device orientations from an allowed orientation set, built from the container geometry that SwiftUI doesn't turn with it.
    public init(_ allowedOrientations: [FUInterfaceOrientation] = FUInterfaceOrientation.allCases, isOn: Bool = true, systemRotation: FUSystemRotationBehavior = .lockedOrientation, animation: Animation? = .easeInOut(duration: 0.3), @ViewBuilder content: @escaping (AutoRotatingGeometryProxy) -> Content) {
        self.mode = .allowed(allowedOrientations, systemRotation: systemRotation)
        self.isOn = isOn
        self.animation = animation
        self.content = content
    }

    /// A view that holds a frame fixed to the device, and turns its content inside that frame so the content's top faces a chosen edge, as the user sees it, in each orientation.
    ///
    ///     AutoRotatingView(topEdges: [
    ///         .portrait: .top,
    ///         .landscapeRight: .leading,
    ///         .landscapeLeft: .leading,
    ///         .portraitUpsideDown: .top
    ///     ]) {
    ///         Cover()
    ///     }
    ///
    /// Each edge is where the content's top points as the user sees it once the device is in that orientation: `.top` keeps the content upright, `.leading` and `.trailing` point its top to the user's leading and trailing sides, layout-relative like SwiftUI's own edges, and `.bottom` turns it upside down. Landscape right is the device turned clockwise from portrait.
    ///
    /// **An orientation left out of the dictionary leaves the content where it is** on the device. Leave out an orientation the interface doesn't turn to, such as upside down on an iPhone, to keep the content still there. There are two exceptions, where there's no "where it is" to keep:
    /// - When the view first appears in an orientation that isn't in the dictionary, or one that's unknown, such as lying flat, the content takes the entry for the interface's current orientation, and failing that, the first entry in the order portrait, landscape right, landscape left, upside down.
    /// - When a foldable iPhone moves between screens, the content takes the entry for the device orientation on the new screen, and failing that, the entry for the orientation it's most likely held in, judged from how it was held on the old screen.
    ///
    /// The content follows the device's physical orientation on the outer screen, whether or not the app supports it, and the interface's orientation on a foldable iPhone's inner screen, where the system turns the interface to every orientation.
    ///
    /// The frame never moves on the screen. Its host turns it back exactly as far as the system turns the interface, with the system's own timing. The content turns inside it with the same timing, and its width and height change through the turn, so for a moment it doesn't fill the screen. Content that should cover the screen the whole way round extends its edges past its frame.
    /// - Parameters:
    ///   - topEdges: Where the content's top points, as the user sees it, in each orientation of the device. An orientation left out leaves the content where it is.
    ///   - isOn: Toggles ability to rotate views.
    ///   - animation: Animation to use when the content turns on its own, or nil for no animation. When the system turns the interface, the content turns with the system's timing.
    ///   - content: Content to turn, built from the container geometry that SwiftUI doesn't turn with it.
    @available(iOS 17, *)
    public init(topEdges: [FUInterfaceOrientation: Edge], isOn: Bool = true, animation: Animation? = .easeInOut(duration: 0.3), @ViewBuilder content: @escaping (AutoRotatingGeometryProxy) -> Content) {
        self.mode = .topEdges(topEdges)
        self.isOn = isOn
        self.animation = animation
        self.content = content
    }

    /// A view that holds a frame fixed to the device, and turns its content inside that frame so the content's top faces a chosen edge, as the user sees it, in each orientation.
    ///
    /// See `init(topEdges:isOn:animation:content:)` for how the edges and missing orientations work.
    /// - Parameters:
    ///   - topEdges: Where the content's top points, as the user sees it, in each orientation of the device. An orientation left out leaves the content where it is.
    ///   - isOn: Toggles ability to rotate views.
    ///   - animation: Animation to use when the content turns on its own, or nil for no animation. When the system turns the interface, the content turns with the system's timing.
    ///   - content: Content to turn.
    @available(iOS 17, *)
    public init(topEdges: [FUInterfaceOrientation: Edge], isOn: Bool = true, animation: Animation? = .easeInOut(duration: 0.3), @ViewBuilder content: () -> Content) {
        /// Built here rather than stored as a closure, so state the caller reads in it is tracked from the caller's first update.
        let content = content()
        self.init(topEdges: topEdges, isOn: isOn, animation: animation, content: { _ in content })
    }

    public var body: some View {
        switch mode {
        case let .allowed(allowedOrientations, systemRotation):
            AutoRotatingLayer(allowedOrientations, isOn: isOn, systemRotation: systemRotation, animation: animation, content: content)
        case let .topEdges(topEdges):
            if #available(iOS 17, *) {
                /// Portrait is the screen's own portrait on either screen of a foldable iPhone, so the outer layer's frame is fixed to the device.
                AutoRotatingLayer([.portrait], isOn: isOn, systemRotation: .locked, animation: animation) { _ in
                    AutoRotatingLayer(presenting: .presenting(topEdges: topEdges, layoutDirection: layoutDirection), isOn: isOn, systemRotation: .locked, animation: animation, content: content)
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
    static func presenting(topEdges: [FUInterfaceOrientation: Edge], layoutDirection: LayoutDirection) -> Self {
        Dictionary(uniqueKeysWithValues: topEdges.map { orientation, edge in
            (orientation, orientation.presenting(up: edge.physical(layoutDirection)))
        })
    }
}

internal extension Edge {
    /// The edge with leading and trailing as left and right, from an edge named in a layout direction.
    func physical(_ layoutDirection: LayoutDirection) -> Edge {
        guard layoutDirection == .rightToLeft else { return self }
        switch self {
        case .leading: return .trailing
        case .trailing: return .leading
        case .top, .bottom: return self
        }
    }
}
#endif
