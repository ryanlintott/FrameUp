//
//  RotationMatchingOrientationViewModifier.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2020-12-31.
//

import SwiftUI

public struct RotationMatchingOrientationViewModifier: ViewModifier {
    @State private var contentOrientation: UIDeviceOrientation? = nil
    @State private var deviceOrientation: UIDeviceOrientation? = nil
        
    let isOn: Bool
    let allowedOrientations: Set<UIDeviceOrientation>
    let animation: Animation?
    let screenOrientations: [UIDeviceOrientation] = [.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown]
    
    public init(isOn: Bool? = nil, allowedOrientations: Set<UIDeviceOrientation>? = nil, withAnimation animation: Animation? = nil) {
        self.isOn = isOn ?? true
        self.allowedOrientations = allowedOrientations ?? [.portrait, .landscapeLeft, .landscapeRight]
        self.animation = animation
    }

    var rotation: Angle {
        guard isOn else { return .zero }
        
        switch (deviceOrientation, contentOrientation) {
        case (.portrait, .landscapeLeft), (.landscapeLeft, .portraitUpsideDown), (.portraitUpsideDown, .landscapeRight), (.landscapeRight, .portrait):
            return .degrees(90)
        case (.portrait, .landscapeRight), (.landscapeRight, .portraitUpsideDown), (.portraitUpsideDown, .landscapeLeft), (.landscapeLeft, .portrait):
            return .degrees(-90)
        case (.portrait, .portraitUpsideDown), (.landscapeRight, .landscapeLeft), (.portraitUpsideDown, .portrait), (.landscapeLeft, .landscapeRight):
            return .degrees(180)
        default:
            return .zero
        }
    }
    
    var isLandscape: Bool {
        switch (deviceOrientation, contentOrientation) {
        case (.portrait, .landscapeLeft), (.portrait, .landscapeRight), (.portraitUpsideDown, .landscapeLeft), (.portraitUpsideDown, .landscapeRight):
            return true
        case (nil, _):
            return !allowedOrientations.contains(.portrait)
        default:
            return false
        }
    }
    
    func changeContentOrientation() {
        if allowedOrientations.contains(UIDevice.current.orientation) {
            contentOrientation = UIDevice.current.orientation
        }
        
        if contentOrientation == nil {
            contentOrientation = screenOrientations.first(where: { allowedOrientations.contains($0) }) ?? .portrait
        }
    }
    
    func changeDeviceOrientation() {
        // Might be .faceUp or .unknown or similar
        let newOrientation = UIDevice.current.orientation
        
        if deviceOrientation == newOrientation { return }
        
        deviceOrientation = InfoDictionary.supportedOrientations.first(where: { $0 == newOrientation }) ?? screenOrientations.first(where: { InfoDictionary.supportedOrientations.contains($0) })
    }
    
    func changeOrientations() {
        if isOn {
            withAnimation(animation) {
                changeDeviceOrientation()
                changeContentOrientation()
                print("Device: \(deviceOrientation?.string ?? "nil") Content: \(contentOrientation?.string ?? "nil")")
            }
        }
    }
    
    public func body(content: Content) -> some View {
        GeometryReader { proxy in
            content
                .rotationEffect(rotation)
                .frame(width: isLandscape ? proxy.size.height : proxy.size.width, height: isLandscape ? proxy.size.width : proxy.size.height)
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
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
    ///   - allowedOrientations: Set of allowed orientations for this view. Default is `[.portrait, .landscapeLeft, .landscapeRight]`
    ///   - isOn: Toggle to turn this modifier on or off.
    ///   - animation: Animation to use when altering the view orientation.
    /// - Returns: A view rotated to match a device orientations from an allowed orientation set.
    public func rotationMatchingOrientation(_ allowedOrientations: Set<UIDeviceOrientation>? = nil, isOn: Bool? = nil, withAnimation animation: Animation? = nil) -> some View {
        self.modifier(RotationMatchingOrientationViewModifier(isOn: self is EmptyView ? false : isOn, allowedOrientations: allowedOrientations, withAnimation: animation))
    }
}
