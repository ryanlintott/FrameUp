//
//  FrameUpExampleApp.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2021-09-14.
//

import SwiftUI

@main
struct FrameUpExampleApp: App {
    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            if #available(iOS 17, *), ProcessInfo.processInfo.arguments.contains("-FUInnerHoldProbeScreen") {
                InnerHoldProbeExample()
            } else if #available(iOS 17, *), ProcessInfo.processInfo.arguments.contains("-FUTopEdgesScreen") {
                TopEdgesProbe(isPresented: .constant(true))
            } else {
                ContentView()
            }
            #else
            ContentView()
            #endif
        }
    }
}
