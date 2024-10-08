//
//  WidgetExamples.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-01.
//

import SwiftUI

struct WidgetExamples: View {
    var body: some View {
        Section {
            NavigationLink(destination: WidgetSizeExample()) {
                Label("WidgetSize", systemImage: "questionmark.app")
            }
            
            NavigationLink(destination: WidgetDemoFrameExample()) {
                Label("WidgetDemoFrame", systemImage: "app")
            }
            
            #if os(iOS)
            NavigationLink(destination: WidgetRelativeShapeExample()) {
                Label("WidgetRelativeShape", systemImage: "app.dashed")
            }
            #endif
        } header: {
            Text("Widget")
        }
    }
}

struct WidgetExamples_Previews: PreviewProvider {
    static var previews: some View {
        List {
            WidgetExamples()
        }
    }
}
