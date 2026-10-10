//
//  View+IfAvailable.swift
//  IfAvailable
//
//  Created by Ryan Lintott on 2023-07-14.
//

import SwiftUI

extension View {
    /// Applies the given transform or returns the untransformed view.
    ///
    /// Useful for availability branching on view modifiers. Do not branch with any properties that may change during runtime as this will cause errors.
    /// - Parameters:
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: The view transformed by the transform.
    @ViewBuilder
    nonisolated func ifAvailable(@ViewBuilder _ transform: (Self) -> (some View)?) -> some View {
        if let transformed = transform(self) {
            transformed
        } else {
            self
        }
    }
    
    /// Applies ``SwiftUICore/View/geometryGroup()`` if available.
    nonisolated public func geometryGroupIfAvailable() -> some View {
        ifAvailable {
            if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
                $0.geometryGroup()
            }
        }
    }

    /// Applies `toolbarVerticalBehavior(_:)` if available.
    ///
    /// It arrived in the iOS 27.1 SDK, whose SwiftUICore is version 8.0.85, so older SDKs skip it at compile time too.
    nonisolated public func toolbarVerticalBehaviorIfAvailable(_ behavior: ToolbarVerticalBehaviorIfAvailable) -> some View {
        ifAvailable {
            #if canImport(SwiftUICore, _version: 8.0.85)
            if #available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *) {
                $0.toolbarVerticalBehavior(behavior.toolbarVerticalBehavior)
            }
            #endif
        }
    }
}

/// Mirrors `ToolbarVerticalBehavior`, which doesn't exist in SDKs older than 27.1, for use with ``SwiftUICore/View/toolbarVerticalBehaviorIfAvailable(_:)``.
public enum ToolbarVerticalBehaviorIfAvailable: Hashable, Sendable {
    /// The system decides whether bars are vertical.
    case automatic
    /// Bars are never vertical.
    case disabled
}

#if canImport(SwiftUICore, _version: 8.0.85)
extension ToolbarVerticalBehaviorIfAvailable {
    @available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
    var toolbarVerticalBehavior: ToolbarVerticalBehavior {
        switch self {
        case .automatic: .automatic
        case .disabled: .disabled
        }
    }
}
#endif
