//
//  View+smartScrollViewID.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2026-10-06.
//

import SwiftUI

#if os(iOS)
extension View {
    /// Gives a `SmartScrollView` an id before iOS 16, so it measures again when the id changes.
    ///
    /// From iOS 16 `SmartScrollView` measures again by itself when more space is available, so the id isn't needed.
    @ViewBuilder
    func smartScrollViewID<ID: Hashable>(_ id: ID) -> some View {
        if #available(iOS 16, *) {
            self
        } else {
            self.id(id)
        }
    }
}
#endif
