//
//  SwiftUIView.swift
//  
//
//  Created by Ryan Lintott on 2021-09-15.
//

import SwiftUI

public struct TabMenuItem<Tab: Hashable>: Equatable {
    public let icon: AnyView
    public let name: String?
    public let tab: Tab
    
    public init(icon: AnyView, name: String? = nil, tab: Tab) {
        self.icon = icon
        self.name = name
        self.tab = tab
    }

    public init(image: Image, name: String? = nil, tab: Tab) {
        self.icon = AnyView(image.resizable())
        self.name = name
        self.tab = tab
    }
    
    public static func == (lhs: TabMenuItem<Tab>, rhs: TabMenuItem<Tab>) -> Bool {
        lhs.tab == rhs.tab
    }
}
