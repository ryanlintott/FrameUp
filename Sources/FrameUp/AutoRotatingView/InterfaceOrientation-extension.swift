//
//  InterfaceOrientation-extension.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-05-23.
//

import SwiftUI

#if os(iOS)
@available(iOS, deprecated: 15.0, message: "This extension is no longer necessary as it's built into the API")
public enum InterfaceOrientation: CaseIterable {
    case portrait
    case landscapeRight
    case landscapeLeft
    case portraitUpsideDown
}

//@available(iOS 15.0, *)
internal extension InterfaceOrientation {
    init?(key: String) {
        switch key {
        case "UIInterfaceOrientationPortrait":
            self = .portrait
        case "UIInterfaceOrientationLandscapeLeft":
            /// UIInterfaceOrientationLandscapeLeft means the interface has turned to the LEFT even though the device has turned to the RIGHT.
            self = .landscapeRight
        case "UIInterfaceOrientationLandscapeRight":
            /// UIInterfaceOrientationLandscapeLeft means the interface has turned to the RIGHT even though the device has turned to the LEFT.
            self = .landscapeLeft
        case "UIInterfaceOrientationPortraitUpsideDown":
            self = .portraitUpsideDown
        default:
            return nil
        }
    }
    
    var isLandscape: Bool {
        switch self {
        case .landscapeLeft, .landscapeRight:
            return true
        default:
            return false
        }
    }
    
    /// The rotation angle required to change this orientation and a new orientation.
    func rotation(to newOrientation: Self) -> Angle {
        switch (self, newOrientation) {
        case (.portrait, .landscapeLeft), (.landscapeLeft, .portraitUpsideDown), (.portraitUpsideDown, .landscapeRight), (.landscapeRight, .portrait):
            return .degrees(-90)
        case (.portrait, .landscapeRight), (.landscapeRight, .portraitUpsideDown), (.portraitUpsideDown, .landscapeLeft), (.landscapeLeft, .portrait):
            return .degrees(90)
        case (.portrait, .portraitUpsideDown), (.landscapeRight, .landscapeLeft), (.portraitUpsideDown, .portrait), (.landscapeLeft, .landscapeRight):
            return .degrees(180)
        default:
            return .zero
        }
    }
    
    var name: String {
        switch self {
        case .portrait:
            return "portrait"
        case .landscapeLeft:
            return "landscapeLeft"
        case .landscapeRight:
            return "landscapeRight"
        case .portraitUpsideDown:
            return "portraitUpsideDown"
        }
    }
}
#endif
