//
//  UIDeviceOrientation-extension.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-05-14.
//

#if os(iOS)
import SwiftUI

internal extension UIDeviceOrientation {
    var interfaceOrientation: FUInterfaceOrientation? {
        switch self {
        case .portrait: .portrait
        case .portraitUpsideDown: .portraitUpsideDown
        case .landscapeLeft: .landscapeLeft
        case .landscapeRight: .landscapeRight
        default: nil
        }
    }
}
#endif
