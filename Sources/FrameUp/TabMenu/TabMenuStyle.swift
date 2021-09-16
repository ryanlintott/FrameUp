//
//  TabMenuStyle.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2021-09-15.
//

import SwiftUI

public struct TabMenuStyle {
    public let selectedItemColor: Color
    public let unselectedItemColor: Color
    
    public init(selectedItemColor: Color, unselectedItemColor: Color) {
        self.selectedItemColor = selectedItemColor
        self.unselectedItemColor = unselectedItemColor
    }
}
