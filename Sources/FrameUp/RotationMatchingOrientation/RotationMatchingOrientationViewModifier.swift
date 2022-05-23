//
//  RotationMatchingOrientationViewModifier.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2020-12-31.
//

import SwiftUI

public struct RotationMatchingOrientationViewModifier: ViewModifier {
    /// The current orientation of the content relative to the device.
    @State private var contentOrientation: InterfaceOrientation? = nil
    /// The current orientation of the device.
    @State private var interfaceOrientation: InterfaceOrientation? = nil
    
    /// Toggle to turn this modifier on or off.
    let isOn: Bool
    /// Allowed orientations for the content.
    let allowedOrientations: [InterfaceOrientation]
    /// Animation to use for the orientation change.
    let animation: Animation?
    
    public init(isOn: Bool? = nil, allowedOrientations: [InterfaceOrientation]? = nil, withAnimation animation: Animation? = nil) {
        self.isOn = isOn ?? true
        self.allowedOrientations = allowedOrientations ?? InterfaceOrientation.allCases
        self.animation = animation
    }
    
    /// Changes the screen orientation based on a new interface orientation.
    func changeInterfaceOrientation(to newOrientation: InterfaceOrientation?) {
        if interfaceOrientation == newOrientation { return }
        
        if let newSupportedOrientation = InfoDictionary.supportedInterfaceOrientations.first(where: { $0 == newOrientation }) {
            interfaceOrientation = newSupportedOrientation
        }
        
        if interfaceOrientation == nil {
            interfaceOrientation = [.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown].first(where: { InfoDictionary.supportedInterfaceOrientations.contains($0) })
        }
    }
    
    /// Changes the content to a new orientation based on the current interface orientation
    func changeContentOrientation(to newOrientation: InterfaceOrientation?, allowedOrientations: [InterfaceOrientation]) {
        if let newOrientation = newOrientation, allowedOrientations.contains(newOrientation) {
            contentOrientation = newOrientation
        }
        
        if contentOrientation == nil {
            contentOrientation = allowedOrientations.first ?? interfaceOrientation ?? .portrait
        }
    }
    
    func changeOrientations(allowedOrientations: [InterfaceOrientation]? = nil) {
        if isOn {
            let allowedOrientations = allowedOrientations ?? self.allowedOrientations
            withAnimation(animation) {
                // if the new device orientation is a valid interface orientation it will not be nil
                let newOrientation = UIDevice.current.orientation.interfaceOrientation
                changeInterfaceOrientation(to: newOrientation)
                changeContentOrientation(to: newOrientation, allowedOrientations: allowedOrientations)
                print("Device: \(newOrientation?.name ?? "nil") Content: \(contentOrientation?.name ?? "nil")")
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
        rotation == .zero || rotation == .degrees(180)
    }
    
    public func body(content: Content) -> some View {
        GeometryReader { proxy in
            content
                .rotationEffect(rotation)
                .frame(width: isMatchingAspectRatio ? proxy.size.width : proxy.size.height, height: isMatchingAspectRatio ? proxy.size.height : proxy.size.width)
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
    }
}

extension View {
    /// Rotates a view and alters it's frame to match device orientations from an allowed orientation set.
    ///
    /// View will use a GeometryReader to take all the available space.
    /// - Parameters:
    ///   - allowedOrientations: Set of allowed orientations for this view. Default is all.
    ///   - isOn: Toggle to turn this modifier on or off.
    ///   - animation: Animation to use when altering the view orientation.
    /// - Returns: A view rotated to match a device orientations from an allowed orientation set.
    public func rotationMatchingOrientation(_ allowedOrientations: [InterfaceOrientation]? = nil, isOn: Bool? = nil, withAnimation animation: Animation? = nil) -> some View {
        self.modifier(RotationMatchingOrientationViewModifier(isOn: self is EmptyView ? false : isOn, allowedOrientations: allowedOrientations, withAnimation: animation))
    }
}
