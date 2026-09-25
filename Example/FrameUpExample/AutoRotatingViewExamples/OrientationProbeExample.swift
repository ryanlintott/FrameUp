//
//  OrientationProbeExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2026-09-24.
//

import os
import SwiftUI

#if os(iOS)
/// Logs device orientation, the scene's interface orientation, the screen and the hinge together, to measure how they relate on each screen of the iPhone Duo.
///
/// Every event is also written to the unified log, so it can be read while the device is folded and rotated:
/// `xcrun simctl spawn booted log stream --level info --predicate 'subsystem == "com.abetterwaytodo.FrameUpExample"'`
struct OrientationProbeExample: View {
    var body: some View {
        OrientationProbeList(onClose: nil)
            .navigationTitle("Orientation Probe")
    }
}

/// The probe's readout. When `onClose` is nil it can present a copy of itself that prefers to lock the interface orientation.
private struct OrientationProbeList: View {
    let onClose: (() -> Void)?
    @State private var latest: OrientationProbeEvent? = nil
    @State private var events: [OrientationProbeEvent] = []
    @State private var isLockedProbePresented: Bool = false

    var body: some View {
        List {
            Section {
                if let onClose {
                    Button("Close locked probe", action: onClose)
                } else if #available(iOS 26, *) {
                    Button("Present with orientation locked") {
                        isLockedProbePresented = true
                    }
                }
            }

            Section("Now") {
                if let latest {
                    ForEach(latest.fields, id: \.0) { name, value in
                        HStack {
                            Text(name)
                            Spacer()
                            Text(value)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section("Events") {
                ForEach(events.reversed()) { event in
                    Text(event.summary)
                        .font(.caption.monospaced())
                }
            }
        }
        .background {
            OrientationProbe(isLockedProbePresented: $isLockedProbePresented) { event in
                latest = event
                events.append(event)
                if events.count > 100 {
                    events.removeFirst()
                }
            }
        }
    }
}

struct OrientationProbeEvent: Identifiable {
    let id = UUID()
    let name: String
    let fields: [(String, String)]

    var summary: String {
        ([name] + fields.map { "\($0)=\($1)" }).joined(separator: " ")
    }
}

private let logger = Logger(subsystem: "com.abetterwaytodo.FrameUpExample", category: "OrientationProbe")

private struct OrientationProbe: UIViewControllerRepresentable {
    @Binding var isLockedProbePresented: Bool
    let onEvent: (OrientationProbeEvent) -> Void

    func makeUIViewController(context: Context) -> OrientationProbeViewController {
        let controller = OrientationProbeViewController()
        controller.probeView.onEvent = onEvent
        return controller
    }

    func updateUIViewController(_ controller: OrientationProbeViewController, context: Context) {
        controller.probeView.onEvent = onEvent
        if #available(iOS 26, *), isLockedProbePresented, controller.presentedViewController == nil {
            let isPresented = $isLockedProbePresented
            let lockedController = OrientationLockedHostingController(
                rootView: OrientationProbeList(onClose: { [weak controller] in
                    controller?.dismiss(animated: true)
                    isPresented.wrappedValue = false
                })
            )
            lockedController.modalPresentationStyle = .fullScreen
            controller.present(lockedController, animated: true)
        }
    }
}

/// Presents the probe full screen with a preference to lock the scene's interface orientation.
@available(iOS 26, *)
private final class OrientationLockedHostingController: UIHostingController<OrientationProbeList> {
    override var prefersInterfaceOrientationLocked: Bool { true }
}

/// Reports the system's rotation transitions, which carry the duration and curve of its animation.
private final class OrientationProbeViewController: UIViewController {
    let probeView = OrientationProbeView()

    override func loadView() {
        view = probeView
    }

    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let start = CACurrentMediaTime()
        probeView.report("transition", extra: [
            ("toSize", size.short),
            ("duration", String(format: "%.3f", coordinator.transitionDuration)),
            ("curve", coordinator.completionCurve.name),
            ("animated", "\(coordinator.isAnimated)")
        ])
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.probeView.report("transitionEnd", extra: [
                ("elapsed", String(format: "%.3f", CACurrentMediaTime() - start))
            ])
        }
    }
}

private final class OrientationProbeView: UIView {
    var onEvent: ((OrientationProbeEvent) -> Void)? = nil

    private var deviceObserver: NSObjectProtocol? = nil
    private var geometryObservation: NSKeyValueObservation? = nil
    private var hingeInteraction: UIInteraction? = nil
    private var hingeDescription = "unavailable"
    private var lastBoundsSize: CGSize = .zero
    /// The scene being observed. Kept when the view leaves its window, which happens during some folds, so events aren't missed.
    private weak var observedScene: UIWindowScene? = nil

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window else {
            report("detached")
            return
        }
        if let observedScene, window.windowScene === observedScene {
            report("reattached")
            return
        }
        stopObserving()
        observedScene = window.windowScene

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        deviceObserver = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.report("device")
                /// Whether the scene's geometry already holds the new interface orientation on the next turn of the run loop, before its KVO fires.
                DispatchQueue.main.async {
                    self?.report("deviceNext")
                }
            }
        }

        if #available(iOS 16, *), let scene = window.windowScene {
            geometryObservation = scene.observe(\.effectiveGeometry, options: [.new]) { [weak self] _, _ in
                MainActor.assumeIsolated {
                    self?.report("geometry")
                    /// The rotation's layer animations are added when the transaction commits, so read them on the next turn of the run loop.
                    DispatchQueue.main.async {
                        self?.reportAnimations()
                    }
                }
            }
        }

        /// `UIHingeInteraction` arrived in the iOS 27.1 SDK, whose UIKit is version 9127.0.85 (9127.0.84 in the iOS 27.0 SDK).
        #if canImport(UIKit, _underlyingVersion: 9127.0.85)
        if #available(iOS 27.1, *) {
            let interaction = UIHingeInteraction { [weak self] _, update in
                guard let self else { return }
                if let hinge = update.hinge {
                    self.hingeDescription = "\(hinge.status.name) \(Int((hinge.angle * 180 / .pi).rounded()))°"
                } else {
                    self.hingeDescription = "none"
                }
                self.report("hinge")
            }
            addInteraction(interaction)
            hingeInteraction = interaction
        }
        #endif

        report("appear")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != lastBoundsSize {
            lastBoundsSize = bounds.size
            report("layout")
        }
    }

    private func stopObserving() {
        if let deviceObserver {
            NotificationCenter.default.removeObserver(deviceObserver)
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
        deviceObserver = nil
        geometryObservation = nil
        if let hingeInteraction {
            removeInteraction(hingeInteraction)
        }
        hingeInteraction = nil
    }

    func report(_ name: String, extra: [(String, String)] = []) {
        var fields = fields()
        fields.insert(contentsOf: extra, at: 1)
        let event = OrientationProbeEvent(name: name, fields: fields)
        logger.info("\(event.summary, privacy: .public)")
        onEvent?(event)
    }

    /// Reports the animations the system added to the window's layer and its direct sublayers, with their duration and timing curve.
    private func reportAnimations() {
        guard let window = window ?? observedScene?.keyWindow else { return }
        var animations: [String] = []
        for layer in [window.layer] + (window.layer.sublayers ?? []) {
            for key in layer.animationKeys() ?? [] {
                guard let animation = layer.animation(forKey: key) else { continue }
                var description = "\(key):\(String(format: "%.3f", animation.duration))"
                if let spring = animation as? CASpringAnimation {
                    description += " spring(mass:\(spring.mass) stiffness:\(spring.stiffness) damping:\(spring.damping) settling:\(String(format: "%.3f", spring.settlingDuration)))"
                } else if let timing = animation.timingFunction {
                    var points: [Float] = []
                    for index in 1...2 {
                        var point: [Float] = [0, 0]
                        timing.getControlPoint(at: index, values: &point)
                        points += point
                    }
                    description += " bezier(\(points.map { String(format: "%.2f", $0) }.joined(separator: ",")))"
                }
                animations.append(description)
            }
        }
        report("animations", extra: [("list", animations.isEmpty ? "none" : animations.joined(separator: " | "))])
    }

    private func fields() -> [(String, String)] {
        let deviceOrientation = UIDevice.current.orientation
        var fields: [(String, String)] = [
            ("t", String(format: "%.3f", CACurrentMediaTime())),
            ("device", deviceOrientation.name),
            ("anim", String(format: "%.3f", UIView.inheritedAnimationDuration))
        ]

        guard let scene = window?.windowScene ?? observedScene, let window = window ?? scene.keyWindow ?? scene.windows.first else {
            return fields
        }

        let interfaceOrientation: UIInterfaceOrientation
        if #available(iOS 16, *) {
            interfaceOrientation = scene.effectiveGeometry.interfaceOrientation
        } else {
            interfaceOrientation = scene.interfaceOrientation
        }
        fields.append(("interface", interfaceOrientation.name))

        /// Quarter turns from the device orientation to the interface orientation, both measured as the device's clockwise turn from portrait. 0 when the interface follows the device on a normal screen.
        if let deviceTurns = deviceOrientation.clockwiseQuarterTurns, let interfaceTurns = interfaceOrientation.deviceClockwiseQuarterTurns {
            fields.append(("offset", "\(((interfaceTurns - deviceTurns) % 4 + 4) % 4 * 90)°"))
        } else {
            fields.append(("offset", "-"))
        }

        if #available(iOS 26, *) {
            fields.append(("locked", "\(scene.effectiveGeometry.isInterfaceOrientationLocked)"))
        }

        let screen = scene.screen
        fields.append(("screen", String(UInt(bitPattern: ObjectIdentifier(screen).hashValue), radix: 16)))
        fields.append(("screenBounds", screen.bounds.size.short))
        fields.append(("screenNative", screen.nativeBounds.size.short))
        fields.append(("windowBounds", window.bounds.size.short))
        fields.append(("supported", window.rootViewController?.supportedInterfaceOrientations.names ?? "-"))
        fields.append(("hinge", hingeDescription))
        /// Whether Bundle resolves the device-specific `~iphone`/`~ipad` key without being asked for it.
        let plistOrientations = (Bundle.main.infoDictionary?["UISupportedInterfaceOrientations"] as? [String])?
            .map { $0.replacingOccurrences(of: "UIInterfaceOrientation", with: "") }
            .joined(separator: ",") ?? "-"
        fields.append(("plist", plistOrientations))
        return fields
    }
}

private extension CGSize {
    var short: String {
        "\(width.formatted())x\(height.formatted())"
    }
}

private extension UIView.AnimationCurve {
    var name: String {
        switch self {
        case .easeInOut: "easeInOut"
        case .easeIn: "easeIn"
        case .easeOut: "easeOut"
        case .linear: "linear"
        @unknown default: "raw(\(rawValue))"
        }
    }
}

private extension UIDeviceOrientation {
    var name: String {
        switch self {
        case .portrait: "portrait"
        case .portraitUpsideDown: "portraitUpsideDown"
        case .landscapeLeft: "landscapeLeft"
        case .landscapeRight: "landscapeRight"
        case .faceUp: "faceUp"
        case .faceDown: "faceDown"
        case .unknown: "unknown"
        @unknown default: "unknown(\(rawValue))"
        }
    }

    /// How far the device is turned clockwise from portrait, in quarter turns.
    var clockwiseQuarterTurns: Int? {
        switch self {
        case .portrait: 0
        case .landscapeRight: 1
        case .portraitUpsideDown: 2
        case .landscapeLeft: 3
        default: nil
        }
    }
}

private extension UIInterfaceOrientation {
    /// Named with UIKit's convention, where the interface turns the opposite way to the device.
    var name: String {
        switch self {
        case .portrait: "UI.portrait"
        case .portraitUpsideDown: "UI.portraitUpsideDown"
        case .landscapeLeft: "UI.landscapeLeft"
        case .landscapeRight: "UI.landscapeRight"
        case .unknown: "UI.unknown"
        @unknown default: "UI.unknown(\(rawValue))"
        }
    }

    /// How far the device is turned clockwise from portrait when the interface has this orientation, in quarter turns.
    var deviceClockwiseQuarterTurns: Int? {
        switch self {
        case .portrait: 0
        case .landscapeLeft: 1
        case .portraitUpsideDown: 2
        case .landscapeRight: 3
        default: nil
        }
    }
}

private extension UIInterfaceOrientationMask {
    var names: String {
        [
            (UIInterfaceOrientationMask.portrait, "P"),
            (.landscapeLeft, "UI.LL"),
            (.landscapeRight, "UI.LR"),
            (.portraitUpsideDown, "PUD")
        ]
        .compactMap { contains($0) ? $1 : nil }
        .joined(separator: ",")
    }
}

#if canImport(UIKit, _underlyingVersion: 9127.0.85)
@available(iOS 27.1, *)
private extension UIHinge.Status {
    var name: String {
        switch self {
        case .unknown: "unknown"
        case .closed: "closed"
        case .partiallyOpen: "partiallyOpen"
        case .fullyOpen: "fullyOpen"
        @unknown default: "unknown(\(rawValue))"
        }
    }
}
#endif
#endif
