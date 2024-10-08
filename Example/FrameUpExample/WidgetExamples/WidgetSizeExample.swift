//
//  WidgetSizeExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2021-09-16.
//

import FrameUp
import SwiftUI

struct WidgetSizeExample: View {
    @State private var widgetSize: WidgetSize = .small

    var size: CGSize {
        #if os(iOS)
        widgetSize.sizeForCurrentDevice(iPadTarget: .homeScreen) ?? widgetSize.minimumSize
        #else
        widgetSize.minimumSize
        #endif
    }
    
    var sizeString: String {
        String(format: "%.1f", size.width) + " x " + String(format: "%.1f", size.height)
    }
    
    var sizes: [WidgetSize] {
        #if os(iOS)
        WidgetSize.supportedSizesForCurrentDevice
        #else
        WidgetSize.allCases
        #endif
    }
    
    var device: String {
        #if os(iOS)
        "this device"
        #else
        "the smallest possible for each widget"
        #endif
    }
    
    var body: some View {
        VStack {
            Text("Sizes below are for \(device). Widget sizes for any device can be found by supplying the screen size.")
                .font(.footnote)
                .padding()
            
            Picker("WidgetSize", selection: $widgetSize) {
                ForEach(sizes, id: \.self) { widgetSize in
                    Text(widgetSize.rawValue)
                }
            }
            .pickerStyle(pickerStyle)
            .padding()
            
            Spacer(minLength: 0)
            
            Color.blue
                .overlay(
                    Text(sizeString)
                        .foregroundColor(.white)
                )
                .frame(size)
            
            Spacer()
        }
        .navigationTitle("WidgetSize")
    }
    
    var pickerStyle: some PickerStyle {
        #if os(tvOS)
        .segmented
        #else
        .menu
        #endif
    }
}

struct WidgetSizeExample_Previews: PreviewProvider {
    static var previews: some View {
        WidgetSizeExample()
    }
}
