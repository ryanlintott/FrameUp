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
    /// The interface orientation the system is expected to turn to, after the device turned to it and before the system starts turning the interface. Only the outermost `AutoRotatingView` sets it.
    @State private var expectedInterfaceOrientation: FUInterfaceOrientation? = nil
    /// The device orientation on the screen the view has just left, or nil before the view has moved between screens. It's a guide to how the device is held on the new screen.
    @State private var previousScreenOrientation: FUInterfaceOrientation? = nil
    /// The rotation of an enclosing `AutoRotatingView`'s content, or a content that never turns if there's none.
    @Environment(\.fuAutoRotatingContent) private var enclosingContent
    /// The system's bar, in this view's frame. The content sees it turned, like the safe area.
    @Environment(\.fuSystemBar) private var systemBar
    /// The latest turn this view started, when it's the outermost `AutoRotatingView`.
    @State private var turn: AutoRotatingTurn? = nil
    /// What this view knows of the system's turn before its state changes, when it's the outermost `AutoRotatingView`.
    @State private var announcement = TurnAnnouncement()
    /// Where the content was when it took the latest turn, or nil if it has changed without a turn since.
    @State private var turnStart: TurnStart? = nil
    /// The clock of the outermost enclosing `AutoRotatingView`, or nil if this is the outermost.
    @Environment(\.fuTurnClock) private var enclosingClock
    /// How content left where it is by the system's turn moves in an enclosing `AutoRotatingView`, or nil if there's none that can be left.
    @Environment(\.fuAutoRotatingHeldBehavior) private var enclosingHeldBehavior
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
    /// Animation to use when the content turns on its own. When the system rotates the interface, the content always turns with the system's own animation. Inside another `AutoRotatingView` the content turns with the outermost one's animation, and this one is used only when its orientation map changes.
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
    func updateOrientations(interfaceOrientation newInterfaceOrientation: FUInterfaceOrientation?, orientationMap: [FUInterfaceOrientation: FUInterfaceOrientation]? = nil, isChangingDeviceScreen: Bool = false) {
        if let newInterfaceOrientation {
            interfaceOrientation = newInterfaceOrientation
        }
        if let newContentOrientation = newContentOrientation(deviceOrientation: deviceOrientation(interfaceOrientation: newInterfaceOrientation ?? interfaceOrientation), orientationMap: orientationMap ?? self.orientationMap, isChangingDeviceScreen: isChangingDeviceScreen) {
            contentOrientation = newContentOrientation
        }
        if let contentOrientation, let interfaceOrientation {
            contentRotation = contentRotation.closestEquivalent(to: contentOrientation.rotation(to: interfaceOrientation))
        }
    }
    
    /// The orientation the content turns to when it's allowed: the device's on the outer screen, and the interface's on the inner screen, where the system always turns the interface with the device but names its orientations a quarter turn from the device's.
    func deviceOrientation(interfaceOrientation: FUInterfaceOrientation?) -> FUInterfaceOrientation? {
        deviceScreen == .inner ? interfaceOrientation : UIDevice.current.orientation.interfaceOrientation
    }
    
    /// True when the content stays as it is in a device orientation, because the device orientation isn't in the map, or the content presents the orientation it's in already.
    func isHeldStill(deviceOrientation: FUInterfaceOrientation?) -> Bool {
        deviceOrientation.flatMap { orientationMap[$0] }.map { $0 == contentOrientation } ?? true
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
            turnStart = nil
            updateOrientations(interfaceOrientation: newInterfaceOrientation, orientationMap: orientationMap, isChangingDeviceScreen: isChangingDeviceScreen)
        }
    }
    
    /// The rotation of the content relative to the interface.
    var interfaceRotation: Angle {
        isOn ? contentRotation : contentRotation.closestEquivalent(to: .zero)
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
    
    /// True when the orientations change as the device turns, and the system's rotation carries the change. Otherwise they change in step with the system's turn, which content inside a locked `AutoRotatingView` needs, as nothing carries a change made beforehand there.
    ///
    /// On the inner screen they always change in step with the system's turn, which is the only place the interface's new orientation is known there.
    var changesAsDeviceTurns: Bool {
        rotationBehavior == .lockedOrientation && enclosingHeldBehavior?.isLocked != true && deviceScreen == .outer
    }
    
    /// True when this is the outermost `AutoRotatingView`, which starts the turns every one inside it takes.
    var isOutermost: Bool {
        enclosingClock == nil
    }
    
    /// Starts a turn that this view and every `AutoRotatingView` inside it take. Only the turn's progress is animated, with the turn's animation.
    /// - Parameters:
    ///   - turn: The turn.
    ///   - startFrame: This view's frame before the system's turn, which has already laid it out at its new size.
    private func start(_ turn: AutoRotatingTurn, startFrame: LayerFrame? = nil) {
        withAnimation(nil) {
            self.turn = turn
            take(turn, startFrame: startFrame)
        }
    }
    
    /// Changes the orientations for a turn the outermost `AutoRotatingView` started, and keeps where the content was so it can turn from there with the turn's progress.
    /// - Parameters:
    ///   - turn: The turn.
    ///   - startFrame: This view's frame before the system's turn, when this is the outermost `AutoRotatingView`.
    private func take(_ turn: AutoRotatingTurn, startFrame: LayerFrame? = nil) {
        switch turn.kind {
        case .screen:
            if isAwaitingScreenLayout {
                moveToScreen()
            }
        case .device:
            /// The orientations change at once, and the system's rotation, which starts a moment later, carries the change. The content keeps its orientation through the turn, though its position is off until the turn ends.
            guard isOn && changesAsDeviceTurns && !isAwaitingScreenLayout else { return }
            turnStart = nil
            updateOrientations(interfaceOrientation: turn.interfaceOrientation)
        case .own:
            /// On the inner screen the system turns the interface with every turn of the device, and on the way to another screen the interface hasn't arrived yet, so the content waits for the system's turn.
            guard isOn && deviceScreen == .outer && !isAwaitingScreenLayout else { return }
            let startRotation = contentRotation
            let systemBar = systemBar
            updateOrientations(interfaceOrientation: turn.interfaceOrientation)
            turnStart = TurnStart(id: turn.id, rotation: startRotation, isHeldStill: contentRotation == startRotation, frame: nil, systemBar: systemBar, turnedSystemBar: systemBar?.rotated(by: startRotation - enclosingContent.startRotation, container: .zero))
        case let .system(angle, _, _):
            guard isOn else { return }
            if isAwaitingScreenLayout {
                moveToScreen()
                return
            }
            /// The orientations may already have changed when the device turned.
            guard !changesAsDeviceTurns, let interfaceOrientation, let newInterfaceOrientation = interfaceOrientation.rotated(by: angle) else { return }
            /// The content turns if the device turns to an allowed orientation it isn't in already, and otherwise stays where it is on the screen, turning back by exactly as much as the interface turns.
            let isHeldStill = isHeldStill(deviceOrientation: deviceOrientation(interfaceOrientation: newInterfaceOrientation))
            let startRotation = contentRotation
            /// Kept in the content's frame, before its rotation changes. The bar is measured outside every rotation and arrives a layout pass after the turn starts (`toolbarVerticalEdge` lags the turn), while the content takes its new rotation at once. Turned by the new rotation, the old measurement lands on the wrong edge of the content and pushes it over for the whole turn.
            let systemBar = systemBar
            if isHeldStill {
                self.interfaceOrientation = newInterfaceOrientation
                contentRotation -= angle
            } else {
                updateOrientations(interfaceOrientation: newInterfaceOrientation)
            }
            turnStart = TurnStart(id: turn.id, rotation: startRotation, isHeldStill: isHeldStill, frame: startFrame, systemBar: systemBar, turnedSystemBar: systemBar?.rotated(by: startRotation - enclosingContent.startRotation, container: .zero))
        }
    }
    
    /// Called when the device turns, in the outermost `AutoRotatingView`.
    ///
    /// When the device turns to an orientation the app supports, the system turns the interface a moment later, in ``interfaceWillRotate(by:coordinator:)``. Otherwise the content turns on its own.
    func deviceOrientationDidChange() {
        guard isOutermost && deviceScreen == .outer && !isAwaitingScreenLayout else { return }
        let deviceOrientation = UIDevice.current.orientation.interfaceOrientation
        /// The notification can arrive after the system has started turning the interface to the device's orientation (measured in iOS 27), and that turn carries it.
        if let deviceOrientation, announcement.isSystemTurning(to: deviceOrientation) { return }
        if let deviceOrientation, deviceOrientation != (interfaceOrientation ?? FUInterfaceOrientation.windowScene), InfoDictionary.supportedInterfaceOrientations.contains(deviceOrientation) {
            expectedInterfaceOrientation = deviceOrientation
            start(AutoRotatingTurn(id: announcement.nextID(), kind: .device, interfaceOrientation: deviceOrientation, animation: nil))
            /// The system starts turning the interface a few milliseconds later (measured in iOS 27). It doesn't when a view controller doesn't support the orientation, or for upside down on an iPhone without a Home button, though the app lists it. No API reports either, so the content turns on its own if no turn has started by then.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                guard expectedInterfaceOrientation == deviceOrientation else { return }
                expectedInterfaceOrientation = nil
                /// Content that changed ahead of the turn goes back to the interface it's still in.
                start(AutoRotatingTurn(id: announcement.nextID(), kind: .own, interfaceOrientation: FUInterfaceOrientation.windowScene, animation: animation))
            }
        } else {
            start(AutoRotatingTurn(id: announcement.nextID(), kind: .own, interfaceOrientation: nil, animation: animation))
        }
    }
    
    /// Called when the system is about to turn the interface, in the outermost `AutoRotatingView`.
    ///
    /// The turn starts inside the system's animation, on a clock that starts when the system's rotation does.
    func interfaceWillRotate(by angle: Angle, coordinator: UIViewControllerTransitionCoordinator) {
        guard isOutermost else { return }
        /// The orientation the device turned to, if it turned first.
        let expectedOrientation = expectedInterfaceOrientation
        expectedInterfaceOrientation = nil
        if isAwaitingScreenLayout {
            /// The interface moves between screens without an animation.
            start(AutoRotatingTurn(id: announcement.nextID(), kind: .screen, interfaceOrientation: nil, animation: nil))
            return
        }
        /// A window that resizes without turning, such as on an iPad, has nothing to turn.
        guard abs(angle.degrees) > 1 else { return }
        let startTime = CACurrentMediaTime()
        let duration = coordinator.transitionDuration
        let newInterfaceOrientation = expectedOrientation ?? (interfaceOrientation ?? FUInterfaceOrientation.windowScene)?.rotated(by: angle)
        /// Set before the system lays the interface out for the turn, so a host knows to keep its content as it is.
        let turn = AutoRotatingTurn(id: announcement.nextID(), kind: .system(angle: angle, startTime: startTime, duration: duration), interfaceOrientation: newInterfaceOrientation, animation: .systemTurn(startTime: startTime, duration: duration))
        announcement.interfaceOrientation = newInterfaceOrientation
        announcement.endTime = startTime + duration
        let startFrame = announcement.frame
        /// The orientations change inside the system's animation, in the layout at the interface's new size.
        let isQueued = coordinator.animate(alongsideTransition: { _ in
            start(turn, startFrame: startFrame)
        })
        if !isQueued {
            start(turn, startFrame: startFrame)
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
        withAnimation(nil) {
            /// The new screen's bar arrives with its layout, not turned from the old screen's.
            turnStart = nil
            updateOrientations(interfaceOrientation: FUInterfaceOrientation.windowScene, isChangingDeviceScreen: true)
        }
    }
    
    /// The latest turn as this view took it, or nil if it didn't take it or has changed since.
    private func currentTurnStart(_ clock: TurnClock?) -> TurnStart? {
        guard let turnStart, let id = clock?.turn?.id, turnStart.id == id else { return nil }
        return turnStart
    }
    
    /// The system's turn while it's under way and a host turns this view's content with it, or nil.
    private func heldTurn(_ clock: TurnClock?, turnStart: TurnStart?, layerTurn: LayerTurn) -> HeldTurn? {
        guard isHostedToHoldStill, let clock, clock.isSystemTurning, let turnStart, case let .system(_, startTime, duration) = clock.turn?.kind else { return nil }
        return HeldTurn(id: turnStart.id, startTime: startTime, duration: duration, rotationChange: layerTurn.rotationChange)
    }
    
    private func layout(clock: TurnClock?) -> some View {
        /// This outer GeometryReader is outside the rotation so its safe area insets are the only correct ones available.
        GeometryReader { safeProxy in
            GeometryReader { fullProxy in
                /// The readers are read in the caller's direction, and their values renamed left to right here, by swapping leading and trailing for a right to left caller. The rotation below is laid out left to right, so leading is always the left of the screen. Values handed to the content are named for the caller's direction again.
                let frame = LayerFrame(size: fullProxy.size, safeAreaInsets: safeProxy.safeAreaInsets.named(for: layoutDirection))
                let isTurnPending = clock.map { $0.isAnnouncedTurnPending || ($0.isSystemTurning && currentTurnStart($0) == nil) } ?? false
                /// The outermost view keeps its frame from before the system announces a turn, as the system lays it out at its new size before the turn reaches it.
                let _ = isOutermost && !isTurnPending ? announcement.frame = frame : ()
                let progress = clock?.progress ?? 1
                let turnStart = currentTurnStart(clock)
                /// Content that didn't take the turn stays where it is relative to the interface, as does content held still. Content that turns to a new orientation takes the short way round relative to its frame.
                let layerTurn = LayerTurn(enclosing: enclosingContent, start: turnStart?.rotation ?? interfaceRotation, target: interfaceRotation, isShortWay: turnStart.map { !$0.isHeldStill } ?? false)
                let heldTurn = heldTurn(clock, turnStart: turnStart, layerTurn: layerTurn)
                /// A host turns its content with Core Animation, so the content takes its new rotation at once. Otherwise it turns at each step of the turn's progress.
                let rotation = heldTurn == nil ? layerTurn.rotation(progress: progress) : layerTurn.targetRotation
                /// The content's frame and safe area move from where they were to where they're going with the turn's progress. The outermost view starts from its frame before the system's turn.
                let targetFrame = frame.rotated(by: layerTurn.targetRotation)
                let contentFrame = (turnStart?.frame ?? frame).rotated(by: layerTurn.startRotation).interpolated(to: targetFrame, progress: progress)
                let maxDimension = max(frame.size.width, frame.size.height)
                /// The system's bar as the content saw it when the turn started, until the bar's new measurement arrives or the turn ends.
                let turnStartSystemBar = turnStart.flatMap { progress < 1 && $0.systemBar == systemBar ? $0.turnedSystemBar : nil }
                /// The full size reader's corners are the container's own. It has to be read in the caller's direction: in any other direction SwiftUI names system UI in a corner for the reader's direction but the rounded corners for the app's (iOS 27.1), and no single swap can fix that.
                let cornerInsets = fullProxy.fuContainerCornerInsets.named(for: layoutDirection)
                let cornerRadii = fullProxy.fuConcentricCornerRadii?.named(for: layoutDirection)
                let geometry = AutoRotatingGeometryProxy(
                    cornerInsets: cornerInsets.rotatedInsets(by: layerTurn.targetRotation, layoutDirection: .leftToRight).named(for: layoutDirection),
                    cornerRadii: cornerRadii?.rotated(by: layerTurn.targetRotation, layoutDirection: .leftToRight).named(for: layoutDirection)
                )
                let contentInsets = contentFrame.safeAreaInsets
                
                let layout = Color.clear.overlay {
                    ZStack {
                        /// This clear view is larger than any content and it helps the rotation effect stay centered. The rotation point is not in the middle of the content due to the safe areas and the content changes sizes when rotating. Trying to keep track of all that in a rotation anchor would be too complicated. It's much easier to make a much larger canvas and rotate that instead.
                        Color.clear
                            .frame(width: maxDimension * 2, height: maxDimension * 2)
                            .allowsHitTesting(false)
                        
                        content(geometry)
                            /// The content frame fills the available area
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            /// Safe areas are applied based on the rotation of the view, and the full area including safe areas is set so that a safe area can be inset inside it.
                            .safeAreaInsets(contentInsets.named(for: layoutDirection))
                            .frame(width: contentFrame.size.width, height: contentFrame.size.height)
                            /// The size at this step of the turn, for content that places views against the frame's edges.
                            .environment(\.fuAnimatedFrameSize, contentFrame.size)
                            /// The turned frame is the container the system's bar is described in, so `systemBarInset` can find where a view inside is relative to it.
                            .coordinateSpace(name: SystemBarContainerSpace())
                            /// The content is laid out in the caller's direction, inside the left to right rotation.
                            .environment(\.layoutDirection, layoutDirection)
                            /// Passes the turn of the content on to any `AutoRotatingView` inside it, which turns relative to it.
                            .environment(\.fuAutoRotatingContent, layerTurn.content)
                            /// The system's bar is turned with the content, like the safe area, so its edge is the edge of the content it's really on.
                            .environment(\.fuSystemBar, (turnStartSystemBar ?? systemBar?.rotated(by: layerTurn.targetRotation, container: .zero))?.rotated(by: .zero, container: CGRect(origin: .zero, size: targetFrame.size)))
                            .environment(\.interfaceTurn, FUInterfaceTurn(interfaceRotation))
                            .environment(\.fuAutoRotatingHeldBehavior, canBeHeld ? rotationBehavior : enclosingHeldBehavior)
                            .environment(\.autoRotatingOrientation, isOn ? contentOrientation : nil)
                            /// Alignment guides are set to move the full size center point to the safe size center point at any rotation
                            .alignmentGuide(VerticalAlignment.center) { d in
                                d[VerticalAlignment.center] + ((contentInsets.top - contentInsets.bottom) / 2)
                            }
                            .alignmentGuide(HorizontalAlignment.center) { d in
                                d[HorizontalAlignment.center] + ((contentInsets.leading - contentInsets.trailing) / 2)
                            }
                    }
                    /// Rotation always occurs around the centre of the content (or a supplied anchor point). It doesn't care about alignment guides as those are for layout.
                    .rotationEffect(rotation)
                    /// These alignment guides move the centre point to the middle of the safe area instead of the
                    .alignmentGuide(VerticalAlignment.center) { d in
                        d[VerticalAlignment.center] + ((frame.safeAreaInsets.bottom - frame.safeAreaInsets.top) / 2)
                    }
                    .alignmentGuide(HorizontalAlignment.center) { d in
                        d[HorizontalAlignment.center] + ((frame.safeAreaInsets.trailing - frame.safeAreaInsets.leading) / 2)
                    }
                }
                /// Laid out left to right so directions are fixed on screen. SwiftUI mirrors a right to left layout, which would turn the content the wrong way and move one of the alignment guides but not the other. The readers above fill their space, so their layout is the same in either direction.
                .environment(\.layoutDirection, .leftToRight)
                
                if #available(iOS 17, *), isHostedToHoldStill {
                    /// Hosted in a view of its own, which UIKit turns in step with the system's rotation so the content stays still on the screen.
                    RotationLockingHost(heldTurn: heldTurn, isTurnPending: isTurnPending, environment: environment, content: layout
                        /// The environment passed to the host is read outside this view's clock, so the clock is set inside it.
                        .environment(\.fuTurnClock, clock))
                } else {
                    layout
                }
            }
            .ignoresSafeArea()
        }
    }
    
    var body: some View {
        TurnClockReader { clock in
            layout(clock: clock)
        }
        /// The outermost view runs the clock every view inside it turns on.
        .modifier(OutermostTurnClock(isOutermost: isOutermost, turn: turn, announcement: announcement))
        .onChange(of: orientationMap) { newValue in
            contentOrientation = nil
            changeOrientations(orientationMap: newValue)
        }
        .onInterfaceRotation(interfaceWillRotate(by:coordinator:))
        /// A view inside another takes each turn the outermost view starts.
        .onChange(of: enclosingClock?.turn) { newValue in
            guard let newValue else { return }
            take(newValue)
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

/// Where an `AutoRotatingView`'s content was when it took a turn.
private struct TurnStart: Equatable {
    /// The id of the turn.
    let id: Int
    /// The content's rotation relative to the interface.
    let rotation: Angle
    /// True when the content stays still on the screen, turning back by exactly as much as the interface turns.
    let isHeldStill: Bool
    /// The outermost view's frame before the system's turn, or nil for a view whose frame hasn't jumped to its new size.
    let frame: LayerFrame?
    /// The system's bar as it was measured, and as the content saw it.
    let systemBar: SystemBar?
    let turnedSystemBar: SystemBar?
}

/// Reads the clock of the outermost `AutoRotatingView`.
private struct TurnClockReader<Content: View>: View {
    @Environment(\.fuTurnClock) private var clock
    let content: (TurnClock?) -> Content
    
    var body: some View {
        content(clock)
    }
}

/// Runs the clock in the outermost `AutoRotatingView`, and passes the enclosing clock on unchanged in any other.
private struct OutermostTurnClock: ViewModifier {
    let isOutermost: Bool
    let turn: AutoRotatingTurn?
    let announcement: TurnAnnouncement
    
    func body(content: Content) -> some View {
        if isOutermost {
            content.turnClock(turn, announcement: announcement)
        } else {
            content
        }
    }
}
#endif
