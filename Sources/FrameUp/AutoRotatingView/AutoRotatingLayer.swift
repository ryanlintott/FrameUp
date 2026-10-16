//
//  AutoRotatingLayer.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2020-12-31.
//

import SwiftUI

#if os(iOS)
/// One turning layer of an ``AutoRotatingView``: a frame that turns and resizes its content to match the device orientation.
///
/// ``AutoRotatingView`` is one of these, or two for `init(topEdges:)`, where a layer locked to portrait holds a frame fixed to the device and a second layer turns the content inside it. Keeping the layers in their own type means `AutoRotatingView` never contains itself.
struct AutoRotatingLayer<Content: View>: View {
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
    /// True once the device is known to fold, so the system can turn the interface to every orientation on its inner screen.
    @State private var hasInnerScreen = false
    /// True from when the view moves to another screen until the system lays the interface out there.
    ///
    /// The hinge reports the new screen before the interface moves to it, when the scene still has the old screen's orientation. The interface then moves with a turn that has no animation, when the scene already has the new orientation (measured in the iPhone Duo simulator, iOS 27.1).
    @State private var isAwaitingScreenLayout = false
    /// The interface orientation the system is expected to turn to, after the device turned to it and before the system starts turning the interface.
    @State private var expectedInterfaceOrientation: FUInterfaceOrientation? = nil
    /// The device orientation on the screen the view has just left, or nil before the view has moved between screens. It's a guide to how the device is held on the new screen.
    @State private var previousScreenOrientation: FUInterfaceOrientation? = nil
    /// The content of an enclosing `AutoRotatingView`, or a content that never turns if there's none.
    @Environment(\.fuAutoRotatingContent) private var enclosingContent
    /// The frame and final safe area an enclosing `AutoRotatingView` gives its content.
    @Environment(\.fuAutoRotatingEnclosingLayout) private var enclosingLayout
    /// The system's bar, in this view's frame. The content sees it turned, like the safe area.
    @Environment(\.fuSystemBar) private var systemBar
    /// The system's bar as the content saw it when the system started turning the interface, kept until the bar's new measurement arrives.
    ///
    /// The bar is measured outside every rotation and arrives a layout pass after the turn starts (`toolbarVerticalEdge` lags the turn), while the content takes its new rotation at once. Turned by the new rotation, the old measurement lands on the wrong edge of the content and pushes it over for the whole turn.
    @State private var turnStartSystemBar: SystemBar? = nil
    /// How content left where it is by the system's turn moves in an enclosing `AutoRotatingView`, or nil if there's none that can be left.
    @Environment(\.fuAutoRotatingHeldBehavior) private var enclosingHeldBehavior
    /// The rotation of the enclosing content during the system's turn of the interface. It's set to where the enclosing content will be when the turn starts, so this content turns in step with the turn rather than when the enclosing view's change reaches it.
    @State private var heldEnclosingContentRotation: Angle? = nil
    /// The system's turn of the interface while it's under way.
    @State private var turn: InterfaceTurn? = nil
    /// The number of times the system has turned the interface, so a turn can tell when another has started after it.
    @State private var turnCount = 0
    /// A turn that holds the content still, from when the system announces it until ``turn`` is set.
    @State private var pendingHeldTurn = PendingHeldTurn()
    /// The environment, passed on to content that is hosted to hold it still on the screen.
    @Environment(\.self) private var environment
    
    /// Allowed orientations for the content.
    let allowedOrientations: [FUInterfaceOrientation]
    /// The orientation the content presents in each orientation of the device. A device orientation that isn't in the map leaves the content as it is.
    let orientationMap: [FUInterfaceOrientation: FUInterfaceOrientation]
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
    init(_ allowedOrientations: [FUInterfaceOrientation] = FUInterfaceOrientation.allCases, isOn: Bool = true, systemRotation: FUSystemRotationBehavior = .lockedOrientation, animation: Animation? = .easeInOut(duration: 0.3), @ViewBuilder content: () -> Content) {
        self.allowedOrientations = allowedOrientations
        self.orientationMap = .identity(allowedOrientations)
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
    init(_ allowedOrientations: [FUInterfaceOrientation] = FUInterfaceOrientation.allCases, isOn: Bool = true, systemRotation: FUSystemRotationBehavior = .lockedOrientation, animation: Animation? = .easeInOut(duration: 0.3), @ViewBuilder content: @escaping (AutoRotatingGeometryProxy) -> Content) {
        self.allowedOrientations = allowedOrientations
        self.orientationMap = .identity(allowedOrientations)
        self.isOn = isOn
        self.systemRotation = systemRotation
        self.animation = animation
        self.content = content
    }
    
    /// A view that presents its content in an orientation chosen for each orientation of the device, rather than always the device's own.
    ///
    /// Each presented orientation is named for the way the device is held when the content is upright, so content presented as `.landscapeRight` while the device is held `.landscapeLeft` is upside down. A device orientation left out of the map leaves the content in the orientation it's in. A map from each allowed orientation to itself is the same as the allowed orientations.
    /// - Parameters:
    ///   - orientationMap: The orientation the content presents in each orientation of the device.
    ///   - isOn: Toggles ability to rotate views.
    ///   - systemRotation: How the content moves while the system turns the interface and the content stays in its orientation.
    ///   - animation: Animation to use when the content turns on its own, or nil for no animation.
    ///   - content: Content to be presented in the mapped orientations, built from the container geometry that SwiftUI doesn't turn with it.
    init(presenting orientationMap: [FUInterfaceOrientation: FUInterfaceOrientation], isOn: Bool = true, systemRotation: FUSystemRotationBehavior = .lockedOrientation, animation: Animation? = .easeInOut(duration: 0.3), @ViewBuilder content: @escaping (AutoRotatingGeometryProxy) -> Content) {
        self.allowedOrientations = FUInterfaceOrientation.allCases.filter(orientationMap.values.contains)
        self.orientationMap = orientationMap
        self.isOn = isOn
        self.systemRotation = systemRotation
        self.animation = animation
        self.content = content
    }
    
    /// A view that presents its content in an orientation chosen for each orientation of the device, rather than always the device's own.
    ///
    /// Content is built once, rather than from the container geometry.
    init(presenting orientationMap: [FUInterfaceOrientation: FUInterfaceOrientation], isOn: Bool = true, systemRotation: FUSystemRotationBehavior = .lockedOrientation, animation: Animation? = .easeInOut(duration: 0.3), @ViewBuilder content: () -> Content) {
        let content = content()
        self.init(presenting: orientationMap, isOn: isOn, systemRotation: systemRotation, animation: animation) { _ in content }
    }
    
    /// - Parameters:
    ///   - deviceOrientation: The current device orientation, if it is a valid interface orientation.
    ///   - isChangingDeviceScreen: True when the view has just moved to another screen of a foldable iPhone.
    func newInterfaceOrientation(deviceOrientation: FUInterfaceOrientation?, isChangingDeviceScreen: Bool) -> FUInterfaceOrientation? {
        if isChangingDeviceScreen, deviceScreen == .outer, let nearestSupportedOrientation = deviceOrientation?.nearest(in: InfoDictionary.supportedInterfaceOrientations) {
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
    
    func newContentOrientation(deviceOrientation: FUInterfaceOrientation?, orientationMap: [FUInterfaceOrientation: FUInterfaceOrientation], isChangingDeviceScreen: Bool) -> FUInterfaceOrientation? {
        ContentOrientationChoice.newOrientation(
            deviceOrientation: deviceOrientation,
            interfaceOrientation: interfaceOrientation,
            currentOrientation: contentOrientation,
            orientationMap: orientationMap,
            preferredOrder: allowedOrientations,
            screenChange: isChangingDeviceScreen ? ContentOrientationChoice.ScreenChange(to: deviceScreen, from: previousScreenOrientation) : nil
        )
    }
    
    /// Sets the orientations, and turns the content to match, in the current transaction.
    ///
    /// The content turns to the orientation it presents in the device orientation, if there is one.
    /// - Parameters:
    ///   - newInterfaceOrientation: The new interface orientation, or nil if it hasn't changed.
    ///   - orientationMap: An orientation map to use in place of the current one, when it's changing.
    ///   - isChangingDeviceScreen: True when the view has just moved to another screen of a foldable iPhone.
    ///   - enclosingChange: How far an enclosing `AutoRotatingView`'s content turns at the same time, so this content takes the short way round relative to it.
    func updateOrientations(interfaceOrientation newInterfaceOrientation: FUInterfaceOrientation?, orientationMap: [FUInterfaceOrientation: FUInterfaceOrientation]? = nil, isChangingDeviceScreen: Bool = false, enclosingChange: Angle = .zero) {
        if let newInterfaceOrientation {
            interfaceOrientation = newInterfaceOrientation
        }
        if let newContentOrientation = newContentOrientation(deviceOrientation: deviceOrientation(interfaceOrientation: newInterfaceOrientation ?? interfaceOrientation), orientationMap: orientationMap ?? self.orientationMap, isChangingDeviceScreen: isChangingDeviceScreen) {
            contentOrientation = newContentOrientation
        }
        if let contentOrientation, let interfaceOrientation {
            contentRotation = contentRotation.closestEquivalent(to: contentOrientation.rotation(to: interfaceOrientation), enclosingChange: enclosingChange)
        }
    }
    
    /// The orientation the content turns to when it's allowed: the device's on the outer screen, and the interface's on the inner screen, where the system always turns the interface with the device but names its orientations a quarter turn from the device's.
    func deviceOrientation(interfaceOrientation: FUInterfaceOrientation?) -> FUInterfaceOrientation? {
        deviceScreen == .inner ? interfaceOrientation : UIDevice.current.orientation.interfaceOrientation
    }
    
    /// Brings the orientations up to date when the view appears, comes back from the background, starts on another screen, or its orientation map changes.
    /// - Parameters:
    ///   - orientationMap: An orientation map to use in place of the current one, when it's changing.
    ///   - isChangingDeviceScreen: True when the view has just moved to another screen of a foldable iPhone.
    func changeOrientations(orientationMap: [FUInterfaceOrientation: FUInterfaceOrientation]? = nil, isChangingDeviceScreen: Bool = false, isAppearing: Bool = false) {
        guard isOn else { return }
        let newInterfaceOrientation = newInterfaceOrientation(deviceOrientation: UIDevice.current.orientation.interfaceOrientation, isChangingDeviceScreen: isChangingDeviceScreen)
        /// When the interface has a new orientation, such as on a new screen or back from the background, the system has already turned it, so the content takes its place at once. A SwiftUI animation can't match a turn by the system.
        /// A view that appears, or comes back from the background, takes its place at once, as does one whose interface has already turned. A page of a `TabView` that was hidden while the device turned would otherwise turn into place after it appears.
        withAnimation(isAppearing || isChangingDeviceScreen || newInterfaceOrientation != nil ? nil : animation) {
            updateOrientations(interfaceOrientation: newInterfaceOrientation, orientationMap: orientationMap, isChangingDeviceScreen: isChangingDeviceScreen)
        }
    }
    
    /// The rotation of the content relative to the interface.
    var interfaceRotation: Angle {
        isOn ? contentRotation : contentRotation.closestEquivalent(to: .zero)
    }
    
    /// The rotation of the content relative to this view's own frame, which an enclosing `AutoRotatingView` may already have turned.
    var rotation: Angle {
        interfaceRotation - (heldEnclosingContentRotation ?? enclosingContent.rotation)
    }
    
    /// True when the system can turn the interface while the content stays where it is, because the system can turn to an orientation the content doesn't allow.
    ///
    /// On a device that folds, the system turns its inner screen to every orientation, so content that doesn't allow them all can be held on either screen. Content keeps the same host on both screens, so its state survives folding and unfolding.
    var canBeHeld: Bool {
        let systemOrientations = hasInnerScreen ? FUInterfaceOrientation.allCases : InfoDictionary.supportedInterfaceOrientations
        return isOn && !Set(systemOrientations).isSubset(of: allowedOrientations)
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
    
    /// The content, passed on to any `AutoRotatingView` inside it, which turns relative to it.
    var contentState: AutoRotatingContentState {
        AutoRotatingContentState(rotation: interfaceRotation, orientation: isOn ? contentOrientation : nil, orientationMap: orientationMap, turnsWithInterface: isOn && !changesAsDeviceTurns)
    }
    
    /// True when the orientations change as the device turns, and the system's rotation carries the change. Otherwise they change in step with the system's turn, which content inside a locked `AutoRotatingView` needs, as nothing carries a change made beforehand there.
    ///
    /// On the inner screen they always change in step with the system's turn, which is the only place the interface's new orientation is known there.
    var changesAsDeviceTurns: Bool {
        rotationBehavior == .lockedOrientation && enclosingHeldBehavior?.isLocked != true && deviceScreen == .outer
    }
    
    /// Called when the device turns.
    ///
    /// When the device turns to an orientation the app supports, the system turns the interface a moment later, and the orientations change in step with it in ``interfaceWillRotate(by:coordinator:)``. Otherwise the content turns on its own.
    func deviceOrientationDidChange() {
        /// On the inner screen the system turns the interface with every turn of the device, and on the way to another screen the interface hasn't arrived yet, so the content waits for the system's turn.
        guard isOn && deviceScreen == .outer && !isAwaitingScreenLayout else { return }
        let deviceOrientation = UIDevice.current.orientation.interfaceOrientation
        if let deviceOrientation, deviceOrientation != interfaceOrientation, InfoDictionary.supportedInterfaceOrientations.contains(deviceOrientation) {
            expectedInterfaceOrientation = deviceOrientation
            if changesAsDeviceTurns {
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
        /// Kept in the content's frame, before its rotation changes.
        turnStartSystemBar = systemBar?.rotated(by: rotation, container: .zero)
        guard isOn else { return }
        if isAwaitingScreenLayout {
            moveToScreen()
            return
        }
        guard let interfaceOrientation else { return }
        /// A window that resizes without turning, such as on an iPad, has nothing to turn.
        guard let newInterfaceOrientation = interfaceOrientation.rotated(by: angle), newInterfaceOrientation != interfaceOrientation else { return }
        /// The orientations may already have changed when the device turned.
        guard !changesAsDeviceTurns else { return }
        let duration = coordinator.transitionDuration
        turnCount += 1
        let count = turnCount
        /// The content turns if the device turns to an allowed orientation it isn't in already, and otherwise stays where it is on the screen.
        let deviceOrientation = deviceOrientation(interfaceOrientation: newInterfaceOrientation)
        let isHeldStill = contentState.isHeldStill(deviceOrientation: deviceOrientation)
        /// An enclosing `AutoRotatingView` changes its rotation without an animation, and its change reaches this content a few frames into the turn, later still in a hosted view. This content turns relative to where the enclosing content will be, worked out now, so its orientation, frame and rotation all change together as the turn starts.
        heldEnclosingContentRotation = enclosingContent.rotation
        let enclosingRotation = enclosingContent.rotation(afterInterfaceTurnBy: angle, to: newInterfaceOrientation, deviceOrientation: deviceOrientation)
        /// What this content sees turn is its rotation relative to the enclosing content, so that's what takes the short way round.
        let enclosingChange = enclosingRotation - enclosingContent.rotation
        /// Hosted content that turns to a new orientation is turned by its host too, with the same timing as the system's rotation, so it stays in step with the window rather than lagging behind it on a SwiftUI animation.
        let isTurnedByHost = !isHeldStill && isHostedToHoldStill
        let hostedRotation: Angle? = isTurnedByHost ? newContentOrientation(deviceOrientation: deviceOrientation, orientationMap: orientationMap, isChangingDeviceScreen: false).map { contentRotation.closestEquivalent(to: $0.rotation(to: newInterfaceOrientation), enclosingChange: enclosingChange) - enclosingRotation } : nil
        /// Set before the system lays the interface out for the turn, so the host knows to hold its content still. Content that isn't hosted, because it allows every orientation the app supports, is carried by the system's animation instead.
        turn = InterfaceTurn(id: count, duration: duration, isHeldStill: isHeldStill || isTurnedByHost, rotation: hostedRotation)
        pendingHeldTurn.id = isHeldStill || isTurnedByHost ? count : nil
        coordinator.animate(alongsideTransition: { _ in
            if isTurnedByHost {
                /// The content takes its new orientation at once, and the host turns it there from where it was.
                withAnimation(nil) {
                    updateOrientations(interfaceOrientation: newInterfaceOrientation, enclosingChange: enclosingChange)
                    heldEnclosingContentRotation = enclosingRotation
                }
            } else if isHeldStill {
                /// The content turns back by exactly as much as the interface turns, in the opposite direction, and the host holds it still through the system's animation.
                withAnimation(nil) {
                    self.interfaceOrientation = newInterfaceOrientation
                    contentRotation -= angle
                    heldEnclosingContentRotation = enclosingRotation
                }
            } else {
                /// Relative to its frame the content turns with a SwiftUI animation timed like the system's, which only has to look smooth, since the frame is either turning with the interface or held still.
                withAnimation(.interfaceTurn(duration: duration)) {
                    updateOrientations(interfaceOrientation: newInterfaceOrientation, enclosingChange: enclosingChange)
                    heldEnclosingContentRotation = enclosingRotation
                }
            }
        })
        /// The coordinator's completion runs at once for a half turn (iOS 27), so the turn is treated as finished after its duration instead.
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            guard count == turnCount else { return }
            turn = nil
            pendingHeldTurn.id = nil
            heldEnclosingContentRotation = nil
            turnStartSystemBar = nil
        }
    }
    
    /// Called when the hinge of a device that folds reports the screen, once when it first reports and then whenever the screen changes.
    private func changeScreen(to screen: FUDeviceScreen, isFirstReport: Bool) {
        if !hasInnerScreen {
            withAnimation(nil) {
                hasInnerScreen = true
            }
        }
        guard screen != deviceScreen else { return }
        /// Read on the old screen, before the view moves.
        let previousOrientation = isFirstReport ? nil : deviceOrientation(interfaceOrientation: interfaceOrientation)
        withAnimation(nil) {
            previousScreenOrientation = previousOrientation
            deviceScreen = screen
        }
        if isFirstReport {
            /// The interface is already on the screen the view starts on.
            changeOrientations(isChangingDeviceScreen: true)
            return
        }
        isAwaitingScreenLayout = true
        /// The system lays the interface out on the new screen a few milliseconds later (measured in the iPhone Duo simulator, iOS 27.1). If it doesn't, the content takes its place on the new screen anyway.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            guard isAwaitingScreenLayout else { return }
            moveToScreen()
        }
    }
    
    /// Gives the content its place on a new screen once the interface has moved there. The scene has the new screen's orientation by then. The content takes its orientation on the new screen (see `ContentOrientationChoice`) at once, as the system's move between screens has no animation.
    private func moveToScreen() {
        isAwaitingScreenLayout = false
        /// The new screen's bar arrives with its layout, not turned from the old screen's.
        turnStartSystemBar = nil
        /// A turn under way on the old screen ends with the move.
        turnCount += 1
        turn = nil
        pendingHeldTurn.id = nil
        heldEnclosingContentRotation = nil
        withAnimation(nil) {
            updateOrientations(interfaceOrientation: FUInterfaceOrientation.windowScene, isChangingDeviceScreen: true)
        }
    }
    
    var body: some View {
        /// This outer GeometryReader is outside the rotation so its safe area insets are the only correct ones available.
        GeometryReader { safeProxy in
            GeometryReader { fullProxy in
                /// The readers are read in the caller's direction, and their values renamed left to right here, by swapping leading and trailing for a right to left caller. The rotation below is laid out left to right, so leading is always the left of the screen. Values handed to the content are named for the caller's direction again.
                let fullSize = fullProxy.size
                /// Content that fills an enclosing `AutoRotatingView` takes the safe area that view is moving to, rather than the one its animation is passing through. Through a turn the enclosing safe area can move between edges of the frame, and turning each step of that with this content's new rotation would send the safe area the long way round.
                let fillsEnclosingLayout = enclosingLayout.map { abs($0.size.width - fullSize.width) < 1 && abs($0.size.height - fullSize.height) < 1 } ?? false
                let safeAreaInsets = (fillsEnclosingLayout ? enclosingLayout?.safeAreaInsets : nil) ?? safeProxy.safeAreaInsets.named(for: layoutDirection)
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
                            /// Safe areas are applied based on the rotation of the view, and the full area including safe areas is set so that a safe area can be inset inside it.
                            .modifier(HeldLayout(insets: rotatedSafeAreaInsets.named(for: layoutDirection), size: rotatedFullSize))
                            /// The turned frame is the container the system's bar is described in, so `systemBarInset` can find where a view inside is relative to it.
                            .coordinateSpace(name: SystemBarContainerSpace())
                            /// The content is laid out in the caller's direction, inside the left to right rotation.
                            .environment(\.layoutDirection, layoutDirection)
                            /// Passes the turn of the content on to any `AutoRotatingView` inside it, which turns relative to it.
                            .environment(\.fuAutoRotatingContent, contentState)
                            .environment(\.fuAutoRotatingEnclosingLayout, AutoRotatingEnclosingLayout(size: rotatedFullSize, safeAreaInsets: rotatedSafeAreaInsets))
                            /// The system's bar is turned with the content, like the safe area, so its edge is the edge of the content it's really on.
                            .environment(\.fuSystemBar, (turnStartSystemBar ?? systemBar?.rotated(by: rotation, container: .zero))?.rotated(by: .zero, container: CGRect(origin: .zero, size: rotatedFullSize)))
                            .environment(\.interfaceTurn, FUInterfaceTurn(interfaceRotation))
                            .environment(\.fuAutoRotatingHeldBehavior, canBeHeld ? rotationBehavior : enclosingHeldBehavior)
                            .environment(\.autoRotatingOrientation, isOn ? contentOrientation : nil)
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
                    RotationLockingHost(rotation: rotation, turn: turn, isTurnPending: pendingHeldTurn.id.map { $0 != turn?.id } ?? false, environment: environment, content: layout)
                } else {
                    layout
                }
            }
            .ignoresSafeArea()
        }
        .onChange(of: orientationMap) { newValue in
            contentOrientation = nil
            changeOrientations(orientationMap: newValue)
        }
        .onInterfaceRotation(interfaceWillRotate(by:coordinator:))
        /// The bar's new measurement has arrived, so the content takes it, turned by its new rotation.
        .onChange(of: systemBar) { _ in
            turnStartSystemBar = nil
        }
        .onChange(of: enclosingContent.rotation) { newValue in
            /// Usually the enclosing content arrives where this content expected it. If not, this content follows it.
            guard let heldRotation = heldEnclosingContentRotation, heldRotation != newValue else { return }
            withAnimation(turn.map { .easeInOut(duration: $0.duration) }) {
                heldEnclosingContentRotation = newValue
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            deviceOrientationDidChange()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            changeOrientations(isAppearing: true)
        }
        .onAppear {
            changeOrientations(isAppearing: true)
        }
        .onHingeScreenChange(changeScreen(to:isFirstReport:))
    }
}

/// A turn that holds the content still, from when the system announces it until the turn's state reaches the view.
///
/// SwiftUI lays the interface out at its new size before state set when the system announces a turn reaches the view (measured in iOS 27). That layout has the new size and safe area but the old rotation. A reference keeps the turn visible to that layout, so a ``RotationLockingHost`` keeps the content as it was, and the safe area animates from where it was before the turn.
private final class PendingHeldTurn {
    var id: Int? = nil
}

/// Applies the safe area and the full frame around it, and while a ``RotationLockingHost`` turns the content in step with the system's rotation, moves them to their new place with an animation timed like the system's.
///
/// The rest of the layout changes at once during that turn, as the content's rotation and the alignment that moves its pivot are measured in different frames, and animating them would move the content off its place. The safe area is interpolated here and laid out again on every frame. The frame's width and height animate too: the host turns the content with Core Animation but can't animate SwiftUI's layout, so without this the content takes its new size on the turn's first frame, while it's still at its old angle, and leaves part of the window uncovered until the turn ends.
private struct HeldLayout: ViewModifier {
    let insets: EdgeInsets
    let size: CGSize
    @Environment(\.fuCounterRotationDuration) private var counterRotationDuration

    func body(content: Content) -> some View {
        if #available(iOS 17, *) {
            content
                .transaction { transaction in
                    if let counterRotationDuration {
                        transaction.animation = .easeInOut(duration: counterRotationDuration)
                    }
                } body: { content in
                    content
                        .animatableSafeAreaInsets(insets)
                        /// The size is laid out again at each step of the turn, like the safe area, so the content changes shape with the turn rather than taking its final shape as the turn starts.
                        .animatableFrame(size)
                }
        } else {
            content
                .safeAreaInsets(insets)
                .frame(size)
        }
    }
}
#endif
