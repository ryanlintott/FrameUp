//
//  SystemVerticalBarGeometryReader.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2026-10-09.
//

import SwiftUI

#if os(iOS)
/// Measures where a tab menu goes in the system's vertical column.
///
/// The measurement uses `reservedRegions`, which arrived in the iOS 27.1 SDK and needs iOS 27.1. Elsewhere it measures nothing, which is fine, since there's no column to measure.
@available(iOS 16, *)
struct SystemVerticalBarGeometryReader: ViewModifier {
    /// The column's edge, or nil when the menu isn't using it.
    let edge: HorizontalEdge?
    let itemCount: Int
    /// The last good measurement. Mid-turn, SwiftUI can report the new edge a layout pass before the safe area moves to it (measured on the iPhone Duo), so a pass with no answer keeps the last one rather than making the menu jump.
    @Binding var geometry: SystemVerticalBarGeometry?

    func body(content: Content) -> some View {
        /// The iOS 27.1 SDK's SwiftUICore is version 8.0.85 (8.0.84 in the iOS 27.0 SDK). Both SDKs ship the same Swift compiler, so a compiler version check can't tell them apart.
        #if canImport(SwiftUICore, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            let edge = edge
            let itemCount = itemCount
            content
                .onGeometryChange(for: SystemVerticalBarGeometry?.self) { proxy in
                    /// A region's frame already includes its margins: SwiftUI reports the same frame and margins as UIKit's `reservedRegions(kind:)`, whose frame is documented to include them (measured on the iPhone Duo: a 40 point hinge frame with 20 point margins, centred on the fold).
                    let occlusionFrames = proxy.reservedRegions(kind: .occlusion).map(\.frame)
                    let divisionFrames = proxy.reservedRegions(kind: .division, options: .includeInactive).map(\.frame)
                    return SystemVerticalBarGeometry(
                        edge: edge,
                        contentSize: proxy.size,
                        safeAreaInsets: proxy.safeAreaInsets,
                        reservedFrames: occlusionFrames + divisionFrames,
                        itemCount: itemCount
                    )
                } action: { newGeometry in
                    if let newGeometry {
                        geometry = newGeometry
                    }
                }
        } else {
            content
        }
        #else
        content
        #endif
    }
}
#endif
