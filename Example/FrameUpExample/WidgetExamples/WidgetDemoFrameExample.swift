//
//  WidgetDemoFrameExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2021-11-22.
//

import FrameUp
import SwiftUI

struct WidgetDemoFrameExample: View {
    @State private var widgetSize: WidgetSize = .small
    
    #if !os(iOS)
    let iPhoneDemoSize = CGSize(width: 430, height: 932)
    let iPadDemoSize = CGSize(width: 768, height: 1024)
    
    var homeScreenSize: CGSize {
        if widgetSize == .extraLarge {
            return widgetSize.sizeForiPad(screenSize: iPadDemoSize, target: .homeScreen) ?? widgetSize.minimumSize
        } else {
            return widgetSize.sizeForiPhone(screenSize: iPhoneDemoSize) ?? widgetSize.minimumSize
        }
    }
    
    var designCanvasSize: CGSize {
        if widgetSize == .extraLarge {
            return widgetSize.sizeForiPad(screenSize: iPadDemoSize, target: .designCanvas) ?? widgetSize.minimumSize
        } else {
            return widgetSize.sizeForiPhone(screenSize: iPhoneDemoSize) ?? widgetSize.minimumSize
        }
    }
    #endif
    
    func sizeString(_ size: CGSize) -> String {
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
        return "this device"
        #else
        if widgetSize == .extraLarge {
            return "an iPad with screen size \(iPadDemoSize.width)x\(iPadDemoSize.height)"
        } else {
            return "an iPhone with screen size \(iPhoneDemoSize.width)x\(iPhoneDemoSize.height)"
        }
        #endif
    }
    
    var body: some View {
        VStack {
            Text("Demo frames below are for \(device). Demo frames for any device can be created by supplying screen size. iPad demo frames will provide an accurate dimension for the content and scale to the size shown on the home screen. Corner radius used is just an estimate as Apple does not supply these values.")
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
            
            #if os(iOS)
            WidgetDemoFrame(widgetSize) { size, cornerRadius in
                Color.blue
            }
            #else
            WidgetDemoFrame(
                widgetSize: widgetSize,
                designCanvasSize: designCanvasSize,
                homeScreenSize: homeScreenSize
            ) { size, cornerRadius in
                Color.blue
            }
            #endif
            
            Spacer()
        }
        .navigationTitle("WidgetDemoFrame")
    }
    
    var pickerStyle: some PickerStyle {
        #if os(tvOS)
        .segmented
        #else
        .menu
        #endif
    }
}

struct WidgetDemoFrameExample_Previews: PreviewProvider {
    static var previews: some View {
        WidgetDemoFrameExample()
    }
}
