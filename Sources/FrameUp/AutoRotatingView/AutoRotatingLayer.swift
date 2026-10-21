//
//  AutoRotatingLayer.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2020-12-31.
//

import SwiftUI

#if os(iOS)
/// One turning layer of an ``AutoRotatingView``.
///
/// `init(topEdges:)` uses two: a portrait layer fixed to the device, and a layer inside it that turns the content. A separate type means `AutoRotatingView` never contains itself.
struct AutoRotatingLayer<Content: View>: View {
    /// The orientations of the content and the turn it's taking.
    @State private var state = TurnState()
    @Environment(\.layoutDirection) private var layoutDirection
    @State private var deviceScreen: FUDeviceScreen = .outer
    /// True once the device is known to fold.
    @State private var hasInnerScreen = false
    /// The device orientation on the screen the view just left, a guide to how the device is held on the new one.
    @State private var previousScreenOrientation: FUInterfaceOrientation? = nil
    @Environment(\.fuEnclosingContentRotation) private var enclosingContentRotation
    /// The system's bar in this view's frame.
    @Environment(\.fuSystemBar) private var systemBar
    @Environment(\.fuSystemBarIsTurnStart) private var isEnclosingTurnStartSystemBar
    /// The latest turn this view started. Outermost layer only.
    @State private var turn: AutoRotatingTurn? = nil
    /// What this view knows of the system's turn before its state changes. Outermost layer only.
    @State private var announcement = TurnAnnouncement()
    /// The window this view is in, once it's in one.
    @State private var window = WindowReference()
    /// The clock of the outermost layer, or nil if this is the outermost.
    @Environment(\.fuTurnClock) private var enclosingClock
    @Environment(\.fuEnclosingCounterRotation) private var enclosingCounterRotation
    @Environment(\.fuSafeAreaTurn) private var enclosingSafeAreaTurn
    @Environment(\.fuHostHeldOrientations) private var enclosingHostHeldOrientations
    /// Passed on to hosted content, which doesn't inherit it.
    @Environment(\.self) private var environment

    let allowedOrientations: [FUInterfaceOrientation]
    /// The orientation the content presents in each device orientation. A missing device orientation leaves the content as it is.
    let orientationMap: [FUInterfaceOrientation: FUInterfaceOrientation]
    let isOn: Bool
    let counterRotation: FUCounterRotationStyle
    /// Animation for turns the content makes on its own.
    let animation: Animation?
    let content: (AutoRotatingGeometryProxy) -> Content

    /// A layer whose content turns to the device orientation, within the allowed orientations.
    init(_ allowedOrientations: [FUInterfaceOrientation], isOn: Bool, counterRotation: FUCounterRotationStyle, animation: Animation?, @ViewBuilder content: @escaping (AutoRotatingGeometryProxy) -> Content) {
        self.allowedOrientations = allowedOrientations
        self.orientationMap = .identity(allowedOrientations)
        self.isOn = isOn
        self.counterRotation = counterRotation
        self.animation = animation
        self.content = content
    }

    /// A layer whose content presents the orientation the map gives for each device orientation.
    init(presenting orientationMap: [FUInterfaceOrientation: FUInterfaceOrientation], isOn: Bool, counterRotation: FUCounterRotationStyle, animation: Animation?, @ViewBuilder content: @escaping (AutoRotatingGeometryProxy) -> Content) {
        self.allowedOrientations = FUInterfaceOrientation.allCases.filter(orientationMap.values.contains)
        self.orientationMap = orientationMap
        self.isOn = isOn
        self.counterRotation = counterRotation
        self.animation = animation
        self.content = content
    }

    /// The interface orientation to change to, or nil if it hasn't changed.
    /// - Parameters:
    ///   - deviceOrientation: The current device orientation, if it is a valid interface orientation.
    ///   - isChangingDeviceScreen: True when the view has just moved to another screen of a foldable iPhone.
    private func newInterfaceOrientation(deviceOrientation: FUInterfaceOrientation?, isChangingDeviceScreen: Bool) -> FUInterfaceOrientation? {
        if isChangingDeviceScreen, deviceScreen == .outer, let nearestSupportedOrientation = deviceOrientation?.nearest(in: systemOrientations) {
            /// Arriving on the outer screen, the system picks the supported orientation nearest the device's.
            return nearestSupportedOrientation
        } else if let sceneOrientation {
            return sceneOrientation == state.interfaceOrientation ? nil : sceneOrientation
        } else if let newSupportedOrientation = systemOrientations.first(where: { $0 == deviceOrientation }), newSupportedOrientation != state.interfaceOrientation {
            return newSupportedOrientation
        } else if state.interfaceOrientation == nil {
            return [.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown].first(where: systemOrientations.contains)
        } else {
            return nil
        }
    }

    /// The interface orientation of this view's window scene. Before the view is in a window, the app's window scene when it has only one.
    private var sceneOrientation: FUInterfaceOrientation? {
        (window.window?.windowScene ?? .onlyApplicationScene).flatMap(FUInterfaceOrientation.init(windowScene:))
    }

    /// The interface orientations the system can turn this view's window to, or the app's supported orientations before it's in a window.
    private var systemOrientations: [FUInterfaceOrientation] {
        FUInterfaceOrientation.systemOrientations(in: window.window)
    }

    /// The state with a new interface orientation, and the content turned to match.
    /// - Parameters:
    ///   - newInterfaceOrientation: The new interface orientation, or nil if it hasn't changed.
    ///   - orientationMap: An orientation map to use in place of the current one, when it's changing.
    ///   - isChangingDeviceScreen: True when the view has just moved to another screen of a foldable iPhone.
    private func updatingOrientations(_ state: TurnState, interfaceOrientation newInterfaceOrientation: FUInterfaceOrientation?, orientationMap: [FUInterfaceOrientation: FUInterfaceOrientation]? = nil, isChangingDeviceScreen: Bool = false) -> TurnState {
        var state = state
        if let newInterfaceOrientation {
            state.interfaceOrientation = newInterfaceOrientation
        }
        if let newContentOrientation = ContentOrientationChoice.newOrientation(
            deviceOrientation: followedOrientation(interfaceOrientation: state.interfaceOrientation),
            interfaceOrientation: state.interfaceOrientation,
            currentOrientation: state.contentOrientation,
            orientationMap: orientationMap ?? self.orientationMap,
            preferredOrder: allowedOrientations,
            screenChange: isChangingDeviceScreen ? ContentOrientationChoice.ScreenChange(to: deviceScreen, from: previousScreenOrientation) : nil
        ) {
            state.contentOrientation = newContentOrientation
        }
        if let contentOrientation = state.contentOrientation, let interfaceOrientation = state.interfaceOrientation {
            state.contentRotation = state.contentRotation.closestEquivalent(to: contentOrientation.rotation(from: interfaceOrientation).angle)
        }
        return state
    }

    /// The orientation the content follows: the device's on the outer screen, and the interface's on the inner screen, where the system turns the interface with the device.
    private func followedOrientation(interfaceOrientation: FUInterfaceOrientation?) -> FUInterfaceOrientation? {
        deviceScreen == .inner ? interfaceOrientation : UIDevice.current.orientation.interfaceOrientation
    }

    /// True when the content keeps its orientation in a device orientation, because the map leaves it out or the content is in that orientation already.
    private func keepsOrientation(deviceOrientation: FUInterfaceOrientation?, contentOrientation: FUInterfaceOrientation?) -> Bool {
        deviceOrientation.flatMap { orientationMap[$0] }.map { $0 == contentOrientation } ?? true
    }

    /// Brings the orientations up to date when the view appears, comes back from the background, starts on another screen, or its orientation map changes.
    /// - Parameters:
    ///   - orientationMap: An orientation map to use in place of the current one, when it's changing.
    ///   - isChangingDeviceScreen: True when the view has just moved to another screen of a foldable iPhone.
    ///   - isAppearing: True when the view appears or comes back from the background.
    private func changeOrientations(orientationMap: [FUInterfaceOrientation: FUInterfaceOrientation]? = nil, isChangingDeviceScreen: Bool = false, isAppearing: Bool = false) {
        guard isOn else { return }
        let newInterfaceOrientation = newInterfaceOrientation(deviceOrientation: UIDevice.current.orientation.interfaceOrientation, isChangingDeviceScreen: isChangingDeviceScreen)
        /// When the interface has already turned, or the view is appearing, the content takes its place at once.
        withAnimation(isAppearing || isChangingDeviceScreen || newInterfaceOrientation != nil ? nil : animation) {
            state.turnStart = nil
            state = updatingOrientations(state, interfaceOrientation: newInterfaceOrientation, orientationMap: orientationMap, isChangingDeviceScreen: isChangingDeviceScreen)
        }
    }

    /// True when the system can turn the interface to an orientation the content doesn't allow. The inner screen of a foldable iPhone turns to every orientation.
    private var hasUnallowedSystemOrientations: Bool {
        let systemOrientations = hasInnerScreen ? FUInterfaceOrientation.allCases : systemOrientations
        return isOn && !Set(systemOrientations).isSubset(of: allowedOrientations)
    }

    /// How the content handles the system's turn of the interface.
    private var systemTurnHandling: SystemTurnHandling {
        SystemTurnHandling(counterRotation: counterRotation, enclosingCounterRotation: enclosingCounterRotation, hasUnallowedSystemOrientations: hasUnallowedSystemOrientations, deviceScreen: deviceScreen)
    }

    /// True for the outermost layer, which starts the turns every layer inside it takes.
    private var isOutermost: Bool {
        enclosingClock == nil
    }

    /// Starts a turn that this layer and every layer inside it takes. Only the turn's progress is animated.
    /// - Parameters:
    ///   - turn: The turn.
    ///   - startFrame: This view's frame before the system's turn.
    private func start(_ turn: AutoRotatingTurn, startFrame: LayerFrame? = nil) {
        withAnimation(nil) {
            self.turn = turn
            state = taking(turn, startFrame: startFrame, from: state)
        }
    }

    /// The state once this layer takes a turn, keeping where the content was so it can turn from there with the turn's progress.
    /// - Parameters:
    ///   - turn: The turn.
    ///   - startFrame: This view's frame before the system's turn, for the outermost layer.
    ///   - state: The state before the turn.
    func taking(_ turn: AutoRotatingTurn, startFrame: LayerFrame? = nil, from state: TurnState) -> TurnState {
        var state = state
        state.takenTurnID = turn.id
        switch turn.kind {
        case .screen:
            if state.isAwaitingScreenLayout {
                state = movingToScreen(state)
            }
        case .contentOnly:
            /// On the inner screen, or on the way to another screen, the content waits for the system's turn.
            guard isOn && deviceScreen == .outer && !state.isAwaitingScreenLayout else { return state }
            let startRotation = state.contentRotation
            state = updatingOrientations(state, interfaceOrientation: turn.interfaceOrientation)
            state.turnStart = TurnStart(id: turn.id, rotation: startRotation, keepsOrientation: state.contentRotation == startRotation, frame: nil, systemBar: systemBar)
        case let .system(angle, _):
            guard isOn else { return state }
            if state.isAwaitingScreenLayout {
                return movingToScreen(state)
            }
            if systemTurnHandling == .changesAsDeviceTurns {
                /// The orientations change at once, and the system's rotation carries the change.
                guard let newInterfaceOrientation = turn.interfaceOrientation, newInterfaceOrientation != state.interfaceOrientation else { return state }
                state.turnStart = nil
                return updatingOrientations(state, interfaceOrientation: newInterfaceOrientation)
            }
            guard let interfaceOrientation = state.interfaceOrientation, let rotation = FUInterfaceRotation(exactly: angle) else { return state }
            let newInterfaceOrientation = interfaceOrientation.rotated(by: rotation)
            let keepsOrientation = keepsOrientation(deviceOrientation: followedOrientation(interfaceOrientation: newInterfaceOrientation), contentOrientation: state.contentOrientation)
            let startRotation = state.contentRotation
            if keepsOrientation {
                /// Turns back by exactly as much as the interface turns.
                state.interfaceOrientation = newInterfaceOrientation
                state.contentRotation -= angle
            } else {
                state = updatingOrientations(state, interfaceOrientation: newInterfaceOrientation)
            }
            /// The bar is kept from before the turn, as its new measurement arrives a layout pass later.
            state.turnStart = TurnStart(id: turn.id, rotation: startRotation, keepsOrientation: keepsOrientation, frame: startFrame, systemBar: systemBar)
        }
        return state
    }

    /// The state as this layer is laid out. A layer inside another takes the outermost turn in the same layout pass, so it never hands on a turn it hasn't taken.
    private func currentTurnState(_ clock: TurnClock?) -> TurnState {
        guard !isOutermost, let turn = clock?.turn, let takenTurnID = state.takenTurnID, turn.id != takenTurnID else { return state }
        return taking(turn, from: state)
    }

    /// Starts a turn when the device turns. Outermost layer only.
    ///
    /// When the device turns to an orientation the system turns the interface to, the system's turn in ``interfaceWillRotate(by:coordinator:in:)`` carries the change. Otherwise the content turns on its own.
    private func deviceOrientationDidChange() {
        guard isOutermost && deviceScreen == .outer && !state.isAwaitingScreenLayout else { return }
        let deviceOrientation = UIDevice.current.orientation.interfaceOrientation
        /// The notification can arrive after the system's turn to that orientation has started.
        if let deviceOrientation, announcement.isSystemTurning(to: deviceOrientation) { return }
        guard let deviceOrientation, deviceOrientation != (state.interfaceOrientation ?? sceneOrientation), systemOrientations.contains(deviceOrientation), !isSystemRefusing(deviceOrientation) else {
            start(AutoRotatingTurn(id: announcement.nextID(), kind: .contentOnly, interfaceOrientation: nil, animation: animation))
            return
        }
    }

    /// True when an iPhone doesn't turn to upside down although the supported orientations allow it, which no API reports. Read in the device orientation notification, which the system posts inside its rotation animation when it turns.
    private func isSystemRefusing(_ deviceOrientation: FUInterfaceOrientation) -> Bool {
        deviceOrientation == .portraitUpsideDown && UIDevice.current.userInterfaceIdiom == .phone && UIView.inheritedAnimationDuration == 0
    }

    /// Starts the system's turn inside its animation, on a clock that starts with it. Outermost layer only.
    private func interfaceWillRotate(by angle: Angle, coordinator: UIViewControllerTransitionCoordinator, in view: UIView) {
        guard isOutermost else { return }
        if state.isAwaitingScreenLayout {
            /// The interface moves between screens without an animation.
            start(AutoRotatingTurn(id: announcement.nextID(), kind: .screen, interfaceOrientation: nil, animation: nil))
            return
        }
        /// A window that resizes without turning has nothing to turn.
        guard abs(angle.degrees) > 1 else { return }
        let newInterfaceOrientation = FUInterfaceRotation(exactly: angle).flatMap { (state.interfaceOrientation ?? sceneOrientation)?.rotated(by: $0) }
        let systemTurn = announcement.systemTurn(for: coordinator)
        let turn = AutoRotatingTurn(id: systemTurn.id, kind: .system(angle: angle, timing: systemTurn.timing), interfaceOrientation: newInterfaceOrientation, animation: .systemTurn(systemTurn.timing))
        /// Set now, before the system lays the interface out for the turn.
        announcement.interfaceOrientation = newInterfaceOrientation
        let startFrame = announcement.frame
        let isQueued = coordinator.animate(alongsideTransition: { _ in
            systemTurn.timing.measure(in: view)
            start(turn, startFrame: startFrame)
        })
        if !isQueued {
            systemTurn.timing.begin()
            start(turn, startFrame: startFrame)
        }
    }

    /// Brings the orientations up to date with the view's own window once it's in one.
    private func windowDidChange(to newWindow: UIWindow) {
        guard window.window !== newWindow else { return }
        window = WindowReference(window: newWindow)
        guard sceneOrientation != state.interfaceOrientation else { return }
        changeOrientations(isAppearing: true)
    }

    /// Called when the hinge first reports the screen, and whenever the screen changes.
    private func changeScreen(to screen: FUDeviceScreen, isFirstReport: Bool) {
        if !hasInnerScreen {
            withAnimation(nil) {
                hasInnerScreen = true
            }
        }
        guard screen != deviceScreen else { return }
        /// Read on the old screen, before the view moves.
        let previousOrientation = isFirstReport ? nil : followedOrientation(interfaceOrientation: state.interfaceOrientation)
        withAnimation(nil) {
            previousScreenOrientation = previousOrientation
            deviceScreen = screen
        }
        if isFirstReport {
            /// The interface is already on the screen the view starts on.
            changeOrientations(isChangingDeviceScreen: true)
            return
        }
        state.isAwaitingScreenLayout = true
        /// If the interface isn't laid out on the new screen by then, the content moves there anyway.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            guard state.isAwaitingScreenLayout else { return }
            withAnimation(nil) {
                state = movingToScreen(state)
            }
        }
    }

    /// The state on a new screen once the interface has moved there.
    private func movingToScreen(_ state: TurnState) -> TurnState {
        var state = state
        state.isAwaitingScreenLayout = false
        /// The new screen's bar arrives with its layout.
        state.turnStart = nil
        return updatingOrientations(state, interfaceOrientation: sceneOrientation, isChangingDeviceScreen: true)
    }

    /// The latest turn as this layer took it, or nil if it didn't take it or has changed since.
    private func currentTurnStart(_ clock: TurnClock?, state: TurnState) -> TurnStart? {
        guard let turnStart = state.turnStart, let id = clock?.turn?.id, turnStart.id == id else { return nil }
        return turnStart
    }

    /// An animation timed like the system's turn while it's under way and the content is held still, or nil.
    private func heldTurnAnimation(_ clock: TurnClock?, state: TurnState) -> Animation? {
        guard systemTurnHandling == .heldStill, let clock, clock.isSystemTurning, currentTurnStart(clock, state: state) != nil, case let .system(_, timing) = clock.turn?.kind else { return nil }
        return .systemTurn(timing)
    }

    /// The interface orientations the host holds the content still for when the system turns to them.
    private func heldOrientations(_ state: TurnState) -> Set<FUInterfaceOrientation> {
        guard isOn && !state.isAwaitingScreenLayout else { return [] }
        return Set(FUInterfaceOrientation.allCases.filter { keepsOrientation(deviceOrientation: $0, contentOrientation: state.contentOrientation) })
    }

    private func layout(clock: TurnClock?) -> some View {
        /// Outside the rotation, so its safe area insets are correct.
        GeometryReader { safeProxy in
            GeometryReader { fullProxy in
                let frame = LayerFrame(size: fullProxy.size, safeAreaInsets: PhysicalEdgeInsets(safeProxy.safeAreaInsets, layoutDirection: layoutDirection))
                /// The outermost layer keeps its frame from before a turn is announced, to turn from.
                let _ = isOutermost && clock?.isAnnouncedTurnPending != true ? announcement.frame = frame : ()
                let cornerInsets = fullProxy.fuContainerCornerInsets(layoutDirection: layoutDirection)
                let cornerRadii = fullProxy.fuConcentricCornerRadii(layoutDirection: layoutDirection)
                let state = currentTurnState(clock)

                if #available(iOS 17, *), systemTurnHandling == .heldStill {
                    let heldOrientations = heldOrientations(state)
                    /// A host inside another that holds for the same turn leaves it to that one.
                    RotationLockingHost(
                        frame: frame,
                        interfaceOrientation: state.interfaceOrientation,
                        announcement: clock?.announcement,
                        heldOrientations: heldOrientations.subtracting(enclosingHostHeldOrientations),
                        heldTurnAnimation: heldTurnAnimation(clock, state: state),
                        environment: environment
                    ) { hold in
                        turningContent(frame: frame, clock: clock, state: state, hold: hold, cornerInsets: cornerInsets, cornerRadii: cornerRadii)
                            .environment(\.fuHostHeldOrientations, enclosingHostHeldOrientations.union(heldOrientations))
                            /// The host's environment is read outside this view's clock.
                            .environment(\.fuTurnClock, clock)
                    }
                } else {
                    turningContent(frame: frame, clock: clock, state: state, hold: nil, cornerInsets: cornerInsets, cornerRadii: cornerRadii)
                }
            }
            .ignoresSafeArea()
        }
    }

    /// The content, turned and resized in this view's frame for the latest turn.
    /// - Parameters:
    ///   - frame: This view's frame.
    ///   - state: The state as this layer is laid out.
    ///   - hold: How a host holds the content still through the system's turn, or nil when it isn't hosted.
    private func turningContent(frame: LayerFrame, clock: TurnClock?, state: TurnState, hold: RotationHold?, cornerInsets: PhysicalCornerInsets, cornerRadii: PhysicalCornerRadii?) -> some View {
        /// The rotation of the content relative to the interface.
        let interfaceRotation = isOn ? state.contentRotation : state.contentRotation.closestEquivalent(to: .zero)
        let turnGeometry = LayerTurnGeometry(
            frame: frame,
            interfaceRotation: interfaceRotation,
            turnStart: currentTurnStart(clock, state: state),
            hold: hold,
            turn: clock?.turn,
            clockProgress: clock?.progress ?? 1,
            enclosingContentRotation: enclosingContentRotation,
            enclosingSafeAreaTurn: enclosingSafeAreaTurn,
            systemBar: systemBar,
            enclosingIsTurnStartSystemBar: isOutermost ? nil : isEnclosingTurnStartSystemBar
        )
        let targetQuarterTurns = turnGeometry.layerTurn.targetRotation.quarterTurns
        let geometry = AutoRotatingGeometryProxy(
            cornerInsets: cornerInsets.rotatedInsets(quarterTurns: targetQuarterTurns),
            cornerRadii: cornerRadii?.rotated(quarterTurns: targetQuarterTurns),
            layoutDirection: layoutDirection
        )
        let maxDimension = max(frame.size.width, frame.size.height)
        let contentFrame = turnGeometry.contentFrame
        let contentInsets = contentFrame.safeAreaInsets

        return Color.clear.overlay {
            ZStack {
                /// Larger than the content at any rotation, so the turned content never pushes the layout.
                Color.clear
                    .frame(width: maxDimension * 2, height: maxDimension * 2)
                    .allowsHitTesting(false)

                content(geometry)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .safeAreaInsets(contentInsets.edgeInsets(layoutDirection: layoutDirection))
                    .frame(width: contentFrame.size.width, height: contentFrame.size.height)
                    .environment(\.fuSafeAreaTurn, SafeAreaTurn(current: contentInsets, target: turnGeometry.targetInsets))
                    .environment(\.autoRotatingTargetSafeAreaInsets, turnGeometry.targetInsets.edgeInsets(layoutDirection: layoutDirection))
                    .environment(\.fuAnimatedFrameSize, contentFrame.size)
                    .coordinateSpace(name: SystemBarContainerSpace())
                    .environment(\.layoutDirection, layoutDirection)
                    .environment(\.fuEnclosingContentRotation, turnGeometry.layerTurn.contentRotation)
                    .environment(\.fuSystemBar, turnGeometry.systemBar)
                    .environment(\.fuSystemBarIsTurnStart, turnGeometry.isTurnStartSystemBar)
                    .environment(\.interfaceRotation, FUInterfaceRotation(interfaceRotation))
                    .environment(\.fuEnclosingCounterRotation, SystemTurnHandling.passedOnCounterRotation(counterRotation, enclosing: enclosingCounterRotation, hasUnallowedSystemOrientations: hasUnallowedSystemOrientations))
                    .environment(\.autoRotatingOrientation, isOn ? state.contentOrientation : nil)
            }
            /// Turns around the frame's centre, as the system turns the interface.
            .rotationEffect(turnGeometry.rotation)
        }
        /// Fixed left to right, as a mirrored right to left layout would turn the content the wrong way.
        .environment(\.layoutDirection, .leftToRight)
    }

    var body: some View {
        Group {
            if isOutermost {
                TurnClockDriver.start(turn, announcement: announcement) { clock in
                    layout(clock: clock)
                }
            } else {
                layout(clock: enclosingClock)
            }
        }
        .onChange(of: orientationMap) { newValue in
            state.contentOrientation = nil
            changeOrientations(orientationMap: newValue)
        }
        .onInterfaceRotation(interfaceWillRotate(by:coordinator:in:), window: windowDidChange(to:))
        /// A layer inside another takes each turn the outermost one starts.
        .onChange(of: enclosingClock?.turn) { newValue in
            guard let newValue else { return }
            state = taking(newValue, from: state)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            deviceOrientationDidChange()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            changeOrientations(isAppearing: true)
        }
        .onAppear {
            /// A turn started before this view appeared is already in its orientations.
            state.takenTurnID = enclosingClock?.turn?.id ?? 0
            changeOrientations(isAppearing: true)
        }
        .onHingeScreenChange(changeScreen(to:isFirstReport:))
    }
}

/// The orientations of a layer's content and the turn it's taking, which a turn changes together.
struct TurnState: Equatable {
    /// The current orientation of the interface.
    var interfaceOrientation: FUInterfaceOrientation? = nil
    /// The current orientation of the content relative to the device.
    var contentOrientation: FUInterfaceOrientation? = nil
    /// The rotation of the content relative to the interface. It accumulates so animations take the shortest path.
    var contentRotation: Angle = .zero
    /// Where the content was when it took the latest turn, or nil if it has changed without a turn since.
    var turnStart: TurnStart? = nil
    /// True from when the hinge reports a new screen until the interface is laid out there.
    var isAwaitingScreenLayout = false
    /// The id of the latest outermost turn this view has taken or passed over.
    var takenTurnID: Int? = nil
}
#endif
