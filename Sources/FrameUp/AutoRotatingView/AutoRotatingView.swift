//
//  AutoRotatingView.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2020-12-31.
//

import SwiftUI

/// A view that rotates and resizes the content frame to match device orientation.
public struct AutoRotatingView<Content: View>: View {
    /// The current orientation of the content relative to the device.
    @State private var contentOrientation: InterfaceOrientation? = nil
    /// The current orientation of the device.
    @State private var interfaceOrientation: InterfaceOrientation? = nil
    
    /// Allowed orientations for the content.
    let allowedOrientations: [InterfaceOrientation]
    /// Toggle to turn this modifier on or off.
    let isOn: Bool
    /// Animation to use for the orientation change.
    let animation: Animation?
    /// Content for the view
    let content: Content
    
    /// A view that rotates and resizes the content frame to match device orientation.
    ///
    /// View will take all available space.
    /// - Parameters:
    ///   - allowedOrientations: Set of allowed orientations for this view. Default is all.
    ///   - isOn: Toggles ability to rotate views.
    ///   - animation: Animation to use when altering the view orientation.
    /// - Returns: A view rotated to match a device orientations from an allowed orientation set.
    public init(_ allowedOrientations: [InterfaceOrientation] = InterfaceOrientation.allCases, isOn: Bool = true, animation: Animation? = .default, @ViewBuilder content: () -> Content) {
        self.allowedOrientations = allowedOrientations
        self.isOn = isOn
        self.animation = animation
        self.content = content()
    }
    
    func newInterfaceOrientation(deviceOrientation: InterfaceOrientation?) -> InterfaceOrientation? {
        if let newSupportedOrientation = InfoDictionary.supportedInterfaceOrientations.first(where: { $0 == deviceOrientation }), newSupportedOrientation != interfaceOrientation {
            return newSupportedOrientation
        } else if interfaceOrientation == nil {
            return [.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown].first(where: { InfoDictionary.supportedInterfaceOrientations.contains($0) })
        } else {
            return nil
        }
    }
    
    func newContentOrientation(deviceOrientation: InterfaceOrientation?, interfaceOrientation: InterfaceOrientation?, allowedOrientations: [InterfaceOrientation]) -> InterfaceOrientation? {
        if let newOrientation = deviceOrientation, allowedOrientations.contains(newOrientation), newOrientation != contentOrientation {
            return newOrientation
        } else if contentOrientation == nil {
            return allowedOrientations.first ?? interfaceOrientation ?? .portrait
        } else {
            return nil
        }
    }
    
    func changeOrientations(allowedOrientations: [InterfaceOrientation]? = nil) {
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
                
//                print("Device: \(deviceOrientation?.name ?? "nil") Content: \(contentOrientation?.name ?? "nil")")
            }
        }
    }
    
    var rotation: Angle {
        guard
            isOn,
            let contentOrientation = contentOrientation,
            let interfaceOrientation = interfaceOrientation
        else { return .zero }
        
        return contentOrientation.rotation(to: interfaceOrientation)
    }
    
    /// This value is true if the aspect ratio of the device and content orientations match
    var isMatchingAspectRatio: Bool {
        switch rotation {
        case .zero, .degrees(180): return true
        default: return false
        }
    }
    
    public var body: some View {
        Color.clear.overlay(
            GeometryReader { proxy in
                content
                    .rotationEffect(rotation)
                    .frame(isMatchingAspectRatio ? proxy.size : proxy.size.swappingWidthAndHeight)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
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
        )
    }
}
