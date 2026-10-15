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
/// On the inner screen of a foldable iPhone the system ignores an app's supported orientations and always follows the device, so there the content always matches the interface and `allowedOrientations` has no effect.
public struct AutoRotatingView<Content: View>: View {
    /// The current orientation of the content relative to the device.
    @State private var contentOrientation: FUInterfaceOrientation? = nil
    /// The current orientation of the device.
    @State private var interfaceOrientation: FUInterfaceOrientation? = nil
    /// The layout direction used to map safe area insets across the content rotation.
    @Environment(\.layoutDirection) private var layoutDirection
    /// The rotation of the content relative to the interface.
    ///
    /// This angle accumulates rather than resetting to an equivalent angle between -180 and 180 degrees so rotation animations always take the shortest path.
    @State private var contentRotation: Angle = .zero
    /// The device screen the view is on. The system applies the app's supported orientations on the outer screen, and ignores them on the inner screen of a foldable iPhone.
    @State private var deviceScreen: FUDeviceScreen = .outer
    /// The interface orientation the system is expected to turn to, after the device turned to it and before the system starts turning the interface.
    @State private var expectedInterfaceOrientation: FUInterfaceOrientation? = nil
    /// The rotation of the content of an enclosing `AutoRotatingView` relative to the interface, or zero if there is none.
    @Environment(\.fuAutoRotatingContentRotation) private var enclosingContentRotation
    /// How content left where it is by the system's turn moves in an enclosing `AutoRotatingView`, or nil if there's none that can be left.
    @Environment(\.fuAutoRotatingHeldBehavior) private var enclosingHeldBehavior
    /// The rotation of the enclosing content held while the system turns the interface, so a change to it turns this content with an animation timed like the system's rather than at once.
    @State private var heldEnclosingContentRotation: Angle? = nil
    /// The system's turn of the interface while it's under way.
    @State private var turn: InterfaceTurn? = nil
    /// The number of times the system has turned the interface, so a turn can tell when another has started after it.
    @State private var turnCount = 0
    /// The environment, passed on to content that is hosted to hold it still on the screen.
    @Environment(\.self) private var environment
    
    /// Allowed orientations for the content.
    let allowedOrientations: [FUInterfaceOrientation]
    /// Toggle to turn this modifier on or off.
    let isOn: Bool
    /// How the content moves while the system turns the interface to an orientation the content doesn't allow.
    let systemRotation: FUSystemRotationBehavior
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
        self.allowedOrientations = allowedOrientations
        self.isOn = isOn
        self.systemRotation = systemRotation
        self.animation = animation
        /// Built here rather than stored as a closure, so state the caller reads in it is tracked from the caller's first update.
        let content = content()
        self.content = { _ in content }
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
        self.allowedOrientations = allowedOrientations
        self.isOn = isOn
        self.systemRotation = systemRotation
        self.animation = animation
        self.content = content
    }
    
    /// - Parameters:
    ///   - deviceOrientation: The current device orientation, if it is a valid interface orientation.
    ///   - isChangingDeviceScreen: True when the view has just moved to the outer screen from the inner screen of a foldable iPhone.
    func newInterfaceOrientation(deviceOrientation: FUInterfaceOrientation?, isChangingDeviceScreen: Bool) -> FUInterfaceOrientation? {
        if isChangingDeviceScreen, let nearestSupportedOrientation = deviceOrientation?.nearest(in: InfoDictionary.supportedInterfaceOrientations) {
            /// The system picks the supported orientation nearest to the device orientation when a scene arrives on a screen that restricts orientations.
            return nearestSupportedOrientation
        } else if let sceneOrientation = FUInterfaceOrientation.windowScene {
            /// Outside a device orientation notification the scene's orientation is up to date. The device orientation can be unknown, as at launch, or one the system doesn't turn to, such as upside down on an iPhone without a Home button.
            return sceneOrientation == interfaceOrientation ? nil : sceneOrientation
        } else if let newSupportedOrientation = InfoDictionary.supportedInterfaceOrientations.first(where: { $0 == deviceOrientation }), newSupportedOrientation != interfaceOrientation {
            return newSupportedOrientation
        } else if interfaceOrientation == nil {
            return [.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown].first(where: { InfoDictionary.supportedInterfaceOrientations.contains($0) })
        } else {
            return nil
        }
    }
    
    func newContentOrientation(deviceOrientation: FUInterfaceOrientation?, allowedOrientations: [FUInterfaceOrientation], isChangingDeviceScreen: Bool) -> FUInterfaceOrientation? {
        if isChangingDeviceScreen, let nearestAllowedOrientation = deviceOrientation?.nearest(in: allowedOrientations) {
            return nearestAllowedOrientation
        } else if let newOrientation = deviceOrientation, allowedOrientations.contains(newOrientation), newOrientation != contentOrientation {
            return newOrientation
        } else if contentOrientation == nil {
            return allowedOrientations.first ?? interfaceOrientation ?? .portrait
        } else {
            return nil
        }
    }
    
    /// Sets the orientations, and turns the content to match, in the current transaction.
    ///
    /// The content turns to the device orientation if it's allowed.
    /// - Parameters:
    ///   - newInterfaceOrientation: The new interface orientation, or nil if it hasn't changed.
    ///   - allowedOrientations: Allowed orientations to use in place of the current ones, when they are changing.
    ///   - isChangingDeviceScreen: True when the view has just moved to the outer screen from the inner screen of a foldable iPhone.
    func updateOrientations(interfaceOrientation newInterfaceOrientation: FUInterfaceOrientation?, allowedOrientations: [FUInterfaceOrientation]? = nil, isChangingDeviceScreen: Bool = false) {
        if let newInterfaceOrientation {
            interfaceOrientation = newInterfaceOrientation
        }
        if let newContentOrientation = newContentOrientation(deviceOrientation: UIDevice.current.orientation.interfaceOrientation, allowedOrientations: allowedOrientations ?? self.allowedOrientations, isChangingDeviceScreen: isChangingDeviceScreen) {
            contentOrientation = newContentOrientation
        }
        if let contentOrientation, let interfaceOrientation {
            contentRotation = contentRotation.closestEquivalent(to: contentOrientation.rotation(to: interfaceOrientation))
        }
    }
    
    /// Brings the orientations up to date when the view appears, comes back from the background, moves to the outer screen, or its allowed orientations change.
    /// - Parameters:
    ///   - allowedOrientations: Allowed orientations to use in place of the current ones, when they are changing.
    ///   - isChangingDeviceScreen: True when the view has just moved to the outer screen from the inner screen of a foldable iPhone.
    func changeOrientations(allowedOrientations: [FUInterfaceOrientation]? = nil, isChangingDeviceScreen: Bool = false) {
        /// On a screen where the system ignores the app's supported orientations the content always matches the interface, so there is nothing to track.
        guard isOn && deviceScreen == .outer else { return }
        let newInterfaceOrientation = newInterfaceOrientation(deviceOrientation: UIDevice.current.orientation.interfaceOrientation, isChangingDeviceScreen: isChangingDeviceScreen)
        /// When the interface has a new orientation, such as on a new screen or back from the background, the system has already turned it, so the content takes its place at once. A SwiftUI animation can't match a turn by the system.
        withAnimation(isChangingDeviceScreen || newInterfaceOrientation != nil ? nil : animation) {
            updateOrientations(interfaceOrientation: newInterfaceOrientation, allowedOrientations: allowedOrientations, isChangingDeviceScreen: isChangingDeviceScreen)
        }
    }
    
    /// The rotation of the content relative to the interface.
    var interfaceRotation: Angle {
        isOn && deviceScreen == .outer ? contentRotation : contentRotation.closestEquivalent(to: .zero)
    }
    
    /// The rotation of the content relative to this view's own frame, which an enclosing `AutoRotatingView` may already have turned.
    var rotation: Angle {
        interfaceRotation - (heldEnclosingContentRotation ?? enclosingContentRotation)
    }
    
    /// True when the system can turn the interface while the content stays where it is, because the app supports an orientation the content doesn't.
    var canBeHeld: Bool {
        isOn && !Set(InfoDictionary.supportedInterfaceOrientations).isSubset(of: allowedOrientations)
    }
    
    /// How the content moves while the system turns the interface. An enclosing `AutoRotatingView` with `lockedOrientation` sets it for the content inside, so the two stay in step.
    var rotationBehavior: FUSystemRotationBehavior {
        if let enclosingHeldBehavior, !enclosingHeldBehavior.isLocked {
            return enclosingHeldBehavior
        }
        return systemRotation
    }
    
    /// True when the content is hosted to hold it still on the screen while the system turns the interface.
    var isHostedToHoldStill: Bool {
        rotationBehavior.isLocked && canBeHeld
    }
    
    /// Called when the device turns.
    ///
    /// When the device turns to an orientation the app supports, the system turns the interface a moment later, and the orientations change in step with it in ``interfaceWillRotate(by:coordinator:)``. Otherwise the content turns on its own.
    func deviceOrientationDidChange() {
        guard isOn && deviceScreen == .outer else { return }
        let deviceOrientation = UIDevice.current.orientation.interfaceOrientation
        if let deviceOrientation, deviceOrientation != interfaceOrientation, InfoDictionary.supportedInterfaceOrientations.contains(deviceOrientation) {
            expectedInterfaceOrientation = deviceOrientation
            if rotationBehavior == .lockedOrientation {
                /// The orientations change at once, without a SwiftUI animation, and the system's rotation, which starts a moment later, carries the change. The content keeps its orientation through the turn, though its position is off until the turn ends.
                withAnimation(nil) {
                    updateOrientations(interfaceOrientation: deviceOrientation)
                }
            }
            /// The system starts turning the interface a few milliseconds later (measured in iOS 27). It doesn't when a view controller doesn't support the orientation, or for upside down on an iPhone without a Home button, though the app lists it. No API reports either, so the content turns on its own if no turn has started by then.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                guard expectedInterfaceOrientation == deviceOrientation else { return }
                expectedInterfaceOrientation = nil
                withAnimation(animation) {
                    /// Content that changed ahead of the turn goes back to the interface it's still in.
                    updateOrientations(interfaceOrientation: FUInterfaceOrientation.windowScene)
                }
            }
        } else {
            withAnimation(animation) {
                updateOrientations(interfaceOrientation: nil)
            }
        }
    }
    
    /// Called when the system is about to turn the interface.
    ///
    /// The orientations change inside the system's animation. Content that doesn't follow the interface turns back by exactly as much as the interface turns, and its host holds it still on the screen through the system's animation.
    func interfaceWillRotate(by angle: Angle, coordinator: UIViewControllerTransitionCoordinator) {
        expectedInterfaceOrientation = nil
        guard isOn && deviceScreen == .outer, let interfaceOrientation else { return }
        /// A window that resizes without turning, such as on an iPad, has nothing to turn.
        guard let newInterfaceOrientation = interfaceOrientation.rotated(by: angle), newInterfaceOrientation != interfaceOrientation else { return }
        /// With `lockedOrientation`, the orientations already changed when the device turned.
        guard rotationBehavior != .lockedOrientation else { return }
        let duration = coordinator.transitionDuration
        turnCount += 1
        let count = turnCount
        /// The content turns if the device turns to an allowed orientation it isn't in already, and otherwise stays where it is on the screen.
        let deviceOrientation = UIDevice.current.orientation.interfaceOrientation
        let isHeldStill = !(deviceOrientation.map(allowedOrientations.contains) ?? false) || deviceOrientation == contentOrientation
        /// Set before the system lays the interface out for the turn, so the host knows to hold its content still. Content that isn't hosted, because it allows every orientation the app supports, is carried by the system's animation instead.
        turn = InterfaceTurn(id: count, duration: duration, isHeldStill: isHeldStill)
        /// An enclosing `AutoRotatingView` held still on the screen changes its rotation without an animation, which would turn this content at once. Its rotation is held from now, before the enclosing view can change it, and follows with an animation.
        heldEnclosingContentRotation = enclosingContentRotation
        coordinator.animate(alongsideTransition: { _ in
            if isHeldStill {
                /// The content turns back by exactly as much as the interface turns, in the opposite direction, and the host holds it still through the system's animation.
                withAnimation(nil) {
                    self.interfaceOrientation = newInterfaceOrientation
                    contentRotation -= angle
                }
            } else {
                /// Relative to its frame the content turns with a SwiftUI animation timed like the system's, which only has to look smooth, since the frame is either turning with the interface or held still.
                withAnimation(.easeInOut(duration: duration)) {
                    updateOrientations(interfaceOrientation: newInterfaceOrientation)
                }
            }
        })
        /// The coordinator's completion runs at once for a half turn (iOS 27), so the turn is treated as finished after its duration instead.
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            guard count == turnCount else { return }
            turn = nil
            heldEnclosingContentRotation = nil
        }
    }
    
    private func changeScreen(to screen: FUDeviceScreen) {
        guard screen != deviceScreen else { return }
        withAnimation(nil) {
            deviceScreen = screen
        }
        if screen == .outer {
            changeOrientations(isChangingDeviceScreen: true)
        }
    }
    
    public var body: some View {
        /// This outer GeometryReader is outside the rotation so its safe area insets are the only correct ones available.
        GeometryReader { safeProxy in
            GeometryReader { fullProxy in
                /// The readers are read in the caller's direction, and their values renamed left to right here, by swapping leading and trailing for a right to left caller. The rotation below is laid out left to right, so leading is always the left of the screen. Values handed to the content are named for the caller's direction again.
                let safeAreaInsets = safeProxy.safeAreaInsets.named(for: layoutDirection)
                let fullSize = fullProxy.size
                let rotatedFullSize = fullSize.rotated(by: rotation)
                let maxDimension = max(fullSize.width, fullSize.height)
                let rotatedSafeAreaInsets = safeAreaInsets.rotated(by: rotation, layoutDirection: .leftToRight)
                /// The full size reader's corners are the container's own. It has to be read in the caller's direction: in any other direction SwiftUI names system UI in a corner for the reader's direction but the rounded corners for the app's (iOS 27.1), and no single swap can fix that.
                let cornerInsets = fullProxy.fuContainerCornerInsets.named(for: layoutDirection)
                let cornerRadii = fullProxy.fuConcentricCornerRadii?.named(for: layoutDirection)
                let geometry = AutoRotatingGeometryProxy(
                    cornerInsets: cornerInsets.rotatedInsets(by: rotation, layoutDirection: .leftToRight).named(for: layoutDirection),
                    cornerRadii: cornerRadii?.rotated(by: rotation, layoutDirection: .leftToRight).named(for: layoutDirection)
                )
                
                let layout = Color.clear.overlay {
                    ZStack {
                        /// This clear view is larger than any content and it helps the rotation effect stay centered. The rotation point is not in the middle of the content due to the safe areas and the content changes sizes when rotating. Trying to keep track of all that in a rotation anchor would be too complicated. It's much easier to make a much larger canvas and rotate that instead.
                        Color.clear
                            .frame(width: maxDimension * 2, height: maxDimension * 2)
                            .allowsHitTesting(false)
                        
                        content(geometry)
                            /// Any `AutoRotatingView` inside turns with its own animation.
                            .environment(\.fuCounterRotationDuration, nil)
                            /// The content frame fills the available area
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            /// Safe areas are applied based on the rotation of the view
                            .modifier(HeldSafeAreaInsets(insets: rotatedSafeAreaInsets.named(for: layoutDirection)))
                            /// The full area including safe areas is set so that a safe area can be inset inside it
                            .frame(rotatedFullSize)
                            /// The content is laid out in the caller's direction, inside the left to right rotation.
                            .environment(\.layoutDirection, layoutDirection)
                            /// Passes the turn of the content on to any `AutoRotatingView` inside it, which turns relative to it.
                            .environment(\.fuAutoRotatingContentRotation, interfaceRotation)
                            .environment(\.fuAutoRotatingHeldBehavior, canBeHeld ? rotationBehavior : enclosingHeldBehavior)
                            .environment(\.autoRotatingOrientation, isOn && deviceScreen == .outer ? contentOrientation : nil)
                            /// Alignment guides are set to move the full size center point to the safe size center point at any rotation
                            .alignmentGuide(VerticalAlignment.center) { d in
                                d[VerticalAlignment.center] + ((rotatedSafeAreaInsets.top - rotatedSafeAreaInsets.bottom) / 2)
                            }
                            .alignmentGuide(HorizontalAlignment.center) { d in
                                d[HorizontalAlignment.center] + ((rotatedSafeAreaInsets.leading - rotatedSafeAreaInsets.trailing) / 2)
                            }
                    }
                    /// Rotation always occurs around the centre of the content (or a supplied anchor point). It doesn't care about alignment guides as those are for layout.
                    .rotationEffect(rotation)
                    /// These alignment guides move the centre point to the middle of the safe area instead of the
                    .alignmentGuide(VerticalAlignment.center) { d in
                        d[VerticalAlignment.center] + ((safeAreaInsets.bottom - safeAreaInsets.top) / 2)
                    }
                    .alignmentGuide(HorizontalAlignment.center) { d in
                        d[HorizontalAlignment.center] + ((safeAreaInsets.trailing - safeAreaInsets.leading) / 2)
                    }
                }
                /// Laid out left to right so directions are fixed on screen. SwiftUI mirrors a right to left layout, which would turn the content the wrong way and move one of the alignment guides but not the other. The readers above fill their space, so their layout is the same in either direction.
                .environment(\.layoutDirection, .leftToRight)
                
                if #available(iOS 17, *), isHostedToHoldStill {
                    /// Hosted in a view of its own, which UIKit turns back in step with the system's rotation so the content stays still on the screen.
                    RotationLockingHost(rotation: rotation, turn: turn, environment: environment, content: layout)
                } else {
                    layout
                }
            }
            .ignoresSafeArea()
        }
        .onChange(of: allowedOrientations) { newValue in
            contentOrientation = nil
            changeOrientations(allowedOrientations: newValue)
        }
        .onInterfaceRotation(interfaceWillRotate(by:coordinator:))
        .onChange(of: enclosingContentRotation) { newValue in
            guard heldEnclosingContentRotation != nil else { return }
            withAnimation(turn.map { .easeInOut(duration: $0.duration) }) {
                heldEnclosingContentRotation = newValue
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            deviceOrientationDidChange()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            changeOrientations()
        }
        .onAppear {
            changeOrientations()
        }
        .onDeviceScreenChange(changeScreen(to:))
    }
}

/// Applies the safe area, and while a ``RotationLockingHost`` turns the content back in step with the system's rotation, moves it to its new place with an animation timed like the system's.
///
/// The rest of the layout changes at once during that turn, as the content's rotation and the alignment that moves its pivot are measured in different frames, and animating them would move the content off its place. The safe area is interpolated here and laid out again on every frame, so only it animates.
private struct HeldSafeAreaInsets: ViewModifier {
    let insets: EdgeInsets
    @Environment(\.fuCounterRotationDuration) private var counterRotationDuration

    func body(content: Content) -> some View {
        if #available(iOS 17, *) {
            content
                .transaction { transaction in
                    if let counterRotationDuration {
                        transaction.animation = .easeInOut(duration: counterRotationDuration)
                    }
                } body: { content in
                    content.animatableSafeAreaInsets(insets)
                }
        } else {
            content.safeAreaInsets(insets)
        }
    }
}
#endif
