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
        #if os(iOS) || os(macOS) || os(visionOS) || os(watchOS)
        widgetSize.frameForCurrentDevice()?.renderedSize ?? widgetSize.minimumSize
        #else
        /// tvOS has no widgets and so no current device to ask.
        widgetSize.minimumSize
        #endif
    }
    
    var sizeString: String {
        String(format: "%.1f", size.width) + " x " + String(format: "%.1f", size.height)
    }
    
    var device: String {
        #if os(iOS) || os(macOS) || os(visionOS) || os(watchOS)
        "this device"
        #else
        "the smallest possible for each widget"
        #endif
    }
    
    var sizes: [WidgetSize] {
        let supported = WidgetSize.supportedSizesForCurrentDevice
        /// tvOS supports no widget sizes at all, so it lists every one rather than showing an empty picker.
        return supported.isEmpty ? WidgetSize.allCases : supported
    }
    
    var body: some View {
        VStack {
            Text("Sizes below are for \(device). Widget sizes for any device can be found by supplying the platform and screen size.")
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
