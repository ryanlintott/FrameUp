//
//  FrameAdjustmentExamples.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-01.
//

import SwiftUI

struct FrameAdjustmentExamples: View {
    var body: some View {
        Section {
            NavigationLink(destination: WidthReaderExample()) {
                Label("WidthReader", systemImage: "arrow.left.and.right.square")
            }
            
            NavigationLink(destination: HeightReaderExample()) {
                Label("HeightReader", systemImage: "arrow.up.and.down.square")
            }
            
            NavigationLink(destination: OnSizeChangeExample()) {
                Label("OnSizeChange", systemImage: "arrow.up.backward.and.arrow.down.forward")
            }
            
            NavigationLink(destination: RelativePaddingExample()) {
                Label("RelativePadding", systemImage: "percent")
            }
            
            NavigationLink(destination: EqualWidthExample()) {
                Label("EqualWidth", systemImage: "arrow.left.arrow.right.square")
            }
            
            NavigationLink(destination: EqualHeightExample()) {
                Label("EqualHeight", systemImage: "arrow.up.arrow.down.square")
            }
            
            NavigationLink(destination: KeyboardHeightExample()) {
                Label("KeyboardHeight", systemImage: "keyboard")
            }
            
            NavigationLink(destination: ScaledToFrameExample()) {
                Label("ScaledToFrame", systemImage: "rectangle.and.arrow.up.right.and.arrow.down.left")
            }
            
            NavigationLink(destination: OverlappingImageHorizontalExample()) {
                Label("OverlapingImage Horizontal", systemImage: "square.righthalf.fill")
            }
            
            NavigationLink(destination: OverlappingImageVerticalExample()) {
                Label("OverlapingImage Vertical", systemImage: "square.bottomhalf.fill")
            }
        } header: {
            Text("Frame Adjustment")
        }
        
    }
}

struct FrameAdjustmentExamples_Previews: PreviewProvider {
    static var previews: some View {
        List {
            FrameAdjustmentExamples()
        }
    }
}
