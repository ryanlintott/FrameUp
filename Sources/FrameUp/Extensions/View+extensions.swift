//
//  View+extensions.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-09-16.
//

import SwiftUI

public extension View {
    func frame(_ size: CGSize?, alignment: Alignment = .center) -> some View {
        self.frame(width: size?.width, height: size?.height, alignment: alignment)
    }
}
