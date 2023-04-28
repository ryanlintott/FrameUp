//
//  LabelledAction.swift
//  
//
//  Created by Ryan Lintott on 2022-09-11.
//

import SwiftUI

#if os(iOS)
public struct NamedAction {
    public let name: Text
    public let action: () -> Void
}

public extension NamedAction {
    init(_ name: LocalizedStringKey, action: @escaping () -> Void) {
        self.name = Text(name)
        self.action = action
    }
}
#endif
