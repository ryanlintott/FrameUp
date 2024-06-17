//
//  InterfaceOrientation-extension.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-05-23.
//

#if os(iOS)
import SwiftUI

public enum FUInterfaceOrientation: CaseIterable, Sendable {
    case portrait
    case landscapeRight
    case landscapeLeft
    case portraitUpsideDown
}

internal extension FUInterfaceOrientation {
    nonisolated init?(key: String) {
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

@available(iOS 15, macOS 12, watchOS 8, tvOS 15, visionOS 1, * )
internal extension FUInterfaceOrientation {
    init?(_ interfaceOrientation: InterfaceOrientation) {
        switch interfaceOrientation {
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        default: return nil
        }
    }
}
#endif
