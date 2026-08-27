//
//  WidgetSizeProbeBundle.swift
//  WidgetSizeProbe
//
//  Created by Ryan Lintott on 2026-08-24.
//

import SwiftUI
import WidgetKit

@main
struct WidgetSizeProbeBundle: WidgetBundle {
    var body: some Widget {
        WidgetSizeProbe()
        #if os(watchOS)
        /// Only used to attribute a watchOS frame to a placement. See ``PlacementProbe``.
        if #available(watchOS 26.0, *) {
            SmartStackProbe()
            WatchFaceProbe()
        }
        #endif
    }
}
