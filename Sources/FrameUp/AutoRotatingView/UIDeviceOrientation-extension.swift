//
//  UIDeviceOrientation-extension.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-05-14.
//

import SwiftUI

#if os(iOS)
internal extension UIDeviceOrientation {
    var interfaceOrientation: InterfaceOrientation? {
        switch self {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        default:
            return nil
        }
    }
}
#endif
