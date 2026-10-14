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
/// When the device turns to an orientation the app supports but the content doesn't, the system turns the interface and the content stays completely still on the screen. On iOS 17 and later, a view that can be held still this way, one whose allowed orientations leave out an orientation the app supports, hosts its content in a view of its own that UIKit turns back in step with the system's rotation, and the content's safe area moves to its new place with the system's timing. On earlier versions the content turns with the interface and takes its place, without an animation, once the turn ends. The content gets the view's environment, but preferences set inside it, such as a navigation title, don't reach views outside, and changing `allowedOrientations` between a set that covers every orientation the app supports and one that doesn't rebuilds the content. The system clips the window as it turns, so the corners of the screen go dark part way through a turn even while the content is still.
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
    /// The rotation of the enclosing content held while the system turns the interface, so a change to it turns this content with an animation timed like the system's rather than at once.
    @State private var heldEnclosingContentRotation: Angle? = nil
    /// The duration of the system's rotation of the interface while it's under way.
    @State private var interfaceRotationDuration: TimeInterval? = nil
    /// The number of times the system has turned the interface, so a turn can tell when another has started after it.
    @State private var interfaceRotationCount = 0
    /// The environment, passed on to content that is hosted to hold it still on the screen.
    @Environment(\.self) private var environment
    
    /// Allowed orientations for the content.
    let allowedOrientations: [FUInterfaceOrientation]
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
    ///   - animation: Animation to use when the content turns on its own, or nil for no animation. Default is the system's rotation animation, measured as 0.3 seconds ease in and out.
    ///   - content: Content to be rotated to match a device orientations from an allowed orientation set.
    public init(_ allowedOrientations: [FUInterfaceOrientation] = FUInterfaceOrientation.allCases, isOn: Bool = true, animation: Animation? = .easeInOut(duration: 0.3), @ViewBuilder content: () -> Content) {
        self.allowedOrientations = allowedOrientations
        self.isOn = isOn
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
    ///   - animation: Animation to use when the content turns on its own, or nil for no animation. Default is the system's rotation animation, measured as 0.3 seconds ease in and out.
    ///   - content: Content to be rotated to match a device orientations from an allowed orientation set, built from the container geometry that SwiftUI doesn't turn with it.
    public init(_ allowedOrientations: [FUInterfaceOrientation] = FUInterfaceOrientation.allCases, isOn: Bool = true, animation: Animation? = .easeInOut(duration: 0.3), @ViewBuilder content: @escaping (AutoRotatingGeometryProxy) -> Content) {
        self.allowedOrientations = allowedOrientations
        self.isOn = isOn
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
    
    func newContentOrientation(deviceOrientation: FUInterfaceOrientation?, interfaceOrientation: FUInterfaceOrientation?, allowedOrientations: [FUInterfaceOrientation], isChangingDeviceScreen: Bool) -> FUInterfaceOrientation? {
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
    
    /// - Parameters:
    ///   - allowedOrientations: Allowed orientations to use in place of the current ones, when they are changing.
    ///   - isChangingDeviceScreen: True when the view has just moved to the outer screen from the inner screen of a foldable iPhone.
    func changeOrientations(allowedOrientations: [FUInterfaceOrientation]? = nil, isChangingDeviceScreen: Bool = false) {
        /// On a screen where the system ignores the app's supported orientations the content always matches the interface, so there is nothing to track.
        if isOn && deviceScreen == .outer {
            let allowedOrientations = allowedOrientations ?? self.allowedOrientations
            /// if the new device orientation is a valid interface orientation it will not be nil
            let deviceOrientation = UIDevice.current.orientation.interfaceOrientation
            let newInterfaceOrientation = newInterfaceOrientation(deviceOrientation: deviceOrientation, isChangingDeviceScreen: isChangingDeviceScreen)
            let newContentOrientation = newContentOrientation(deviceOrientation: deviceOrientation, interfaceOrientation: newInterfaceOrientation, allowedOrientations: allowedOrientations, isChangingDeviceScreen: isChangingDeviceScreen)
            let changeAnimation: Animation?
            if isChangingDeviceScreen {
                /// Moving between screens is not a rotation. The system replaces the scene's geometry at once.
                changeAnimation = nil
            } else if interfaceOrientation == contentOrientation && newInterfaceOrientation == newContentOrientation {
                /// If interface and content orientations match before and after, there is no need to animate as iOS will handle the animated rotation.
                changeAnimation = nil
            } else if newInterfaceOrientation != nil {
                /// The interface has turned, such as while the app was in the background. The content takes its place at once, as a SwiftUI animation can't match a turn by the system.
                changeAnimation = nil
            } else {
                changeAnimation = animation
            }
            withAnimation(changeAnimation) {
                if let newInterfaceOrientation {
                    interfaceOrientation = newInterfaceOrientation
                }
                if let newContentOrientation {
                    contentOrientation = newContentOrientation
                }
                if let contentOrientation, let interfaceOrientation {
                    contentRotation = contentRotation.closestEquivalent(to: contentOrientation.rotation(to: interfaceOrientation))
                }
            }
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
    
    /// True when the content can be held still on the screen while the system turns the interface, because the app supports an orientation the content doesn't.
    var canHoldStill: Bool {
        isOn && !Set(InfoDictionary.supportedInterfaceOrientations).isSubset(of: allowedOrientations)
    }
    
    /// Called when the device turns.
    ///
    /// When the device turns to an orientation the app supports, the system turns the interface soon after, and the orientations change in step with it in ``interfaceWillRotate(by:coordinator:)``. Otherwise the content turns on its own.
    func deviceOrientationDidChange() {
        guard isOn && deviceScreen == .outer else { return }
        let deviceOrientation = UIDevice.current.orientation.interfaceOrientation
        if let deviceOrientation, deviceOrientation != interfaceOrientation, InfoDictionary.supportedInterfaceOrientations.contains(deviceOrientation) {
            expectedInterfaceOrientation = deviceOrientation
            /// The system starts turning the interface a few milliseconds later (measured in iOS 27). If it doesn't, because a view controller doesn't support the orientation or the device never turns upside down, the content turns on its own.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                guard expectedInterfaceOrientation == deviceOrientation else { return }
                expectedInterfaceOrientation = nil
                changeContentOrientation(animation: animation)
            }
        } else {
            changeContentOrientation(animation: animation)
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
        interfaceRotationCount += 1
        let count = interfaceRotationCount
        guard #available(iOS 17, *) else {
            /// Before iOS 17 the content isn't held still. It turns with the interface, and takes its new place without an animation once the turn ends, so it's right before and after. SwiftUI changes made during the system's turn are carried by UIKit's animation, which distorts the content.
            DispatchQueue.main.asyncAfter(deadline: .now() + coordinator.transitionDuration) {
                guard count == interfaceRotationCount else { return }
                withAnimation(nil) {
                    self.interfaceOrientation = newInterfaceOrientation
                    updateContentOrientation()
                }
            }
            return
        }
        let transitionAnimation = Animation.easeInOut(duration: coordinator.transitionDuration)
        /// An enclosing `AutoRotatingView` held still on the screen changes its rotation without an animation, which would turn this content at once. Its rotation is held from now, before the enclosing view can change it, and follows with an animation.
        heldEnclosingContentRotation = enclosingContentRotation
        coordinator.animate(alongsideTransition: { _ in
            interfaceRotationDuration = coordinator.transitionDuration
            let deviceOrientation = UIDevice.current.orientation.interfaceOrientation
            if deviceOrientation.map(allowedOrientations.contains) ?? false, deviceOrientation != contentOrientation {
                /// The content turns to the new orientation. Relative to its frame it turns with a SwiftUI animation timed like the system's, which only has to look smooth, since the frame is either turning with the interface or held still.
                withAnimation(transitionAnimation) {
                    self.interfaceOrientation = newInterfaceOrientation
                    updateContentOrientation()
                }
            } else {
                /// The content stays where it is on the screen. It turns back by exactly as much as the interface turns, in the opposite direction, and the host holds it still through the system's animation.
                withAnimation(nil) {
                    self.interfaceOrientation = newInterfaceOrientation
                    contentRotation -= angle
                }
            }
        })
        /// The coordinator's completion runs at once for a half turn (iOS 27), so the rotation is treated as finished after its duration instead.
        DispatchQueue.main.asyncAfter(deadline: .now() + coordinator.transitionDuration) {
            guard count == interfaceRotationCount else { return }
            heldEnclosingContentRotation = nil
            interfaceRotationDuration = nil
        }
    }
    
    /// Turns the content to the device orientation if it's allowed, and keeps it turned to match the interface.
    func changeContentOrientation(animation: Animation?) {
        withAnimation(animation) {
            updateContentOrientation()
        }
    }
    
    /// Turns the content to the device orientation if it's allowed, and keeps it turned to match the interface, in the current transaction.
    func updateContentOrientation() {
        if let deviceOrientation = UIDevice.current.orientation.interfaceOrientation, allowedOrientations.contains(deviceOrientation) {
            contentOrientation = deviceOrientation
        }
        if let contentOrientation, let interfaceOrientation {
            contentRotation = contentRotation.closestEquivalent(to: contentOrientation.rotation(to: interfaceOrientation))
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
                
                if #available(iOS 17, *), canHoldStill {
                    /// Hosted in a view of its own, which UIKit turns back in step with the system's rotation so the content stays still on the screen.
                    RotationLockingHost(rotation: rotation, contentOrientation: contentOrientation, allowedOrientations: allowedOrientations, environment: environment, content: layout)
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
            withAnimation(interfaceRotationDuration.map { .easeInOut(duration: $0) }) {
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
                    content.modifier(AnimatableSafeAreaInsets(insets: insets))
                }
        } else {
            content.safeAreaInsets(insets)
        }
    }
}

/// Applies a safe area that's interpolated when it animates, so the content is laid out again at each step.
private struct AnimatableSafeAreaInsets: ViewModifier, @preconcurrency Animatable {
    var insets: EdgeInsets

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get { .init(.init(insets.top, insets.leading), .init(insets.bottom, insets.trailing)) }
        set { insets = EdgeInsets(top: newValue.first.first, leading: newValue.first.second, bottom: newValue.second.first, trailing: newValue.second.second) }
    }

    func body(content: Content) -> some View {
        content.safeAreaInsets(insets)
    }
}

private struct AutoRotatingOrientationKey: EnvironmentKey {
    static let defaultValue: FUInterfaceOrientation? = nil
}

public extension EnvironmentValues {
    /// The orientation of the content of the nearest enclosing `AutoRotatingView`, named for the way the device is held when the content is upright, or nil outside one.
    ///
    /// It's also nil when the view is off, and on the inner screen of a foldable iPhone, where the content always matches the interface.
    ///
    ///     AutoRotatingView([.portrait, .landscapeLeft]) {
    ///         Content()
    ///     }
    ///
    ///     struct Content: View {
    ///         @Environment(\.autoRotatingOrientation) private var orientation
    ///
    ///         var body: some View {
    ///             Text(orientation == .portrait ? "Portrait" : "Landscape")
    ///         }
    ///     }
    var autoRotatingOrientation: FUInterfaceOrientation? {
        get { self[AutoRotatingOrientationKey.self] }
        set { self[AutoRotatingOrientationKey.self] = newValue }
    }
}

private struct AutoRotatingContentRotationKey: EnvironmentKey {
    static let defaultValue: Angle = .zero
}

internal extension EnvironmentValues {
    /// The rotation of the content of the nearest enclosing `AutoRotatingView` relative to the interface.
    var fuAutoRotatingContentRotation: Angle {
        get { self[AutoRotatingContentRotationKey.self] }
        set { self[AutoRotatingContentRotationKey.self] = newValue }
    }
    
    /// The duration of the system's turn while a ``RotationLockingHost`` turns its content back in step with it, or nil.
    var fuCounterRotationDuration: TimeInterval? {
        get { self[CounterRotationDurationKey.self] }
        set { self[CounterRotationDurationKey.self] = newValue }
    }
}

private struct CounterRotationDurationKey: EnvironmentKey {
    static let defaultValue: TimeInterval? = nil
}
#endif
