//
//  ContentView.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2021-09-14.
//

import FrameUp
import SwiftUI

struct ContentView: View {
    var logo: some View {
        Image("FrameUp-logo")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 400)
            .padding()
    }
    
    @ViewBuilder
    var examples: some View {
        LayoutExamples()
        
        AutoRotatingViewExamples()
        
        FrameAdjustmentExamples()
        
        TextExamples()
        
        SmartScrollViewExamples()
        
        FlippingViewExamples()
        
        TabMenuExamples()
        
        WidgetExamples()
        
        FULayoutExamples()
        
        TagViewExamples()
        
        /// These likely won't work
        ExperimentViews()
    }
    
    var body: some View {
        #if os(iOS) || os(tvOS)
        NavigationView {
            VStack {
                logo
                
                List {
                    examples
                }
            }
            .navigationTitle("FrameUp")
            .navigationBarHidden(true)
        }
        .keyboardHeightEnvironmentValue()
        #else
        if #available(macOS 13, *) {
            NavigationSplitView {
                List {
                    logo

                    examples
                }
                .navigationTitle("FrameUp")
            } detail: {
                Text("Select an example.")
            }
        } else {
            NavigationView {
                List {
                    logo
                    
                    examples
                }
                .navigationTitle("FrameUp")
                
                Text("Select an example.")
            }
        }
        #endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
