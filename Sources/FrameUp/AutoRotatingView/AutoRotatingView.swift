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
/// Content is laid out in all the available space including any safe area around it, and a matching safe area is re-created inside the rotation. Content can either respect that safe area or ignore it with `ignoresSafeArea()`, and in both cases it neither steps at the start of a rotation nor drifts off the axis of rotation part way through one.
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
    
    /// Allowed orientations for the content.
    let allowedOrientations: [FUInterfaceOrientation]
    /// Toggle to turn this modifier on or off.
    let isOn: Bool
    /// Animation to use for the orientation change.
    let animation: Animation?
    /// Content for the view
    let content: Content
    
    /// A view that rotates and resizes the content frame to match device orientation.
    ///
    /// View will take all available space, drawing into any safe area around it and re-creating that safe area inside the rotation.
    /// - Parameters:
    ///   - allowedOrientations: Set of allowed orientations for this view. Default is all.
    ///   - isOn: Toggles ability to rotate views.
    ///   - animation: Animation to use when altering the view orientation.
    ///   - content: Content to be rotated to match a device orientations from an allowed orientation set.
    public init(_ allowedOrientations: [FUInterfaceOrientation] = FUInterfaceOrientation.allCases, isOn: Bool = true, animation: Animation? = .default, @ViewBuilder content: () -> Content) {
        self.allowedOrientations = allowedOrientations
        self.isOn = isOn
        self.animation = animation
        self.content = content()
    }
    
    func newInterfaceOrientation(deviceOrientation: FUInterfaceOrientation?) -> FUInterfaceOrientation? {
        if let newSupportedOrientation = InfoDictionary.supportedInterfaceOrientations.first(where: { $0 == deviceOrientation }), newSupportedOrientation != interfaceOrientation {
            return newSupportedOrientation
        } else if interfaceOrientation == nil {
            return [.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown].first(where: { InfoDictionary.supportedInterfaceOrientations.contains($0) })
        } else {
            return nil
        }
    }
    
    func newContentOrientation(deviceOrientation: FUInterfaceOrientation?, interfaceOrientation: FUInterfaceOrientation?, allowedOrientations: [FUInterfaceOrientation]) -> FUInterfaceOrientation? {
        if let newOrientation = deviceOrientation, allowedOrientations.contains(newOrientation), newOrientation != contentOrientation {
            return newOrientation
        } else if contentOrientation == nil {
            return allowedOrientations.first ?? interfaceOrientation ?? .portrait
        } else {
            return nil
        }
    }
    
    func changeOrientations(allowedOrientations: [FUInterfaceOrientation]? = nil) {
        if isOn {
            let allowedOrientations = allowedOrientations ?? self.allowedOrientations
            /// if the new device orientation is a valid interface orientation it will not be nil
            let deviceOrientation = UIDevice.current.orientation.interfaceOrientation
            let newInterfaceOrientation = newInterfaceOrientation(deviceOrientation: deviceOrientation)
            let newContentOrientation = newContentOrientation(deviceOrientation: deviceOrientation, interfaceOrientation: newInterfaceOrientation, allowedOrientations: allowedOrientations)
            let changeAnimation: Animation?
            if interfaceOrientation == contentOrientation && newInterfaceOrientation == newContentOrientation {
                /// If interface and content orientations match before and after, there is no need to animate as iOS will handle the animated rotation.
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
    
    var rotation: Angle {
        isOn ? contentRotation : contentRotation.closestEquivalent(to: .zero)
    }
    
    public var body: some View {
        /// This outer GeometryReader is outside the rotation so its safe area insets are the only correct ones available.
        GeometryReader { outerProxy in
            Color.clear.overlay(
                GeometryReader { proxy in
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background { Color.yellow }
                        .background { Color.pink.ignoresSafeArea() }
                        /// The container's safe area is carried through the rotation, moving directly from the shape it rests in at one end to the shape it rests in at the other.
                        .modifier(
                            RotationWithSafeAreaViewModifier(
                                angle: rotation,
                                containerSize: proxy.size,
                                safeAreaInsets: outerProxy.safeAreaInsets,
                                layoutDirection: layoutDirection
                            )
                        )
                }
            )
            /// The content frame is the full space including the safe area so it does not change when a rotation begins.
            .ignoresSafeArea()
            .onChange(of: allowedOrientations) { newValue in
                contentOrientation = nil
                changeOrientations(allowedOrientations: newValue)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                changeOrientations()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                changeOrientations()
            }
            .onAppear {
                changeOrientations()
            }
        }
    }
}
#endif
