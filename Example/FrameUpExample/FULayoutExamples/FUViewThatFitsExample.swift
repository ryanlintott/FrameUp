//
//  FUViewThatFitsExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-10-31.
//

#if !os(visionOS)
import FrameUp
import SwiftUI

struct FUViewThatFitsExample: View {
    @State private var width: CGFloat = 200
    @State private var height: CGFloat = 200
    
    @State private var fitHoriztonal: Bool = true
    @State private var fitVertical: Bool = true
    
    var fuViewThatFits: FUViewThatFits {
        switch (fitVertical, fitHoriztonal) {
        case (true, true):
            return FUViewThatFits(maxWidth: width, maxHeight: height)
        case (true, false):
            return FUViewThatFits(maxHeight: height)
        case (false, true):
            return FUViewThatFits(maxWidth: width)
        case (false, false):
            return FUViewThatFits(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            fuViewThatFits {
                Color.green.frame(width: 300, height: 300)
                Color.yellow.frame(width: 200, height: 200)
                Color.blue.frame(width: 100, height: 100)
            }
            .frame(width: width, height: height)
            .border(Color.red)
            
            Spacer()
            
            VStack {
                Toggle("Fit Horizontal", isOn: $fitHoriztonal)
                HStack {
                    #if os(tvOS)
                    Text("Width \(width)")
                    Button("-") { width = max(50, width - 50) }
                    Button("+") { width = min(350, width + 50) }
                    #else
                    Text("Width")
                    Slider(value: $width, in: 50...350)
                        .padding()
                    #endif
                }
                
                Toggle("Fit Vertical", isOn: $fitVertical)
                HStack {
                    #if os(tvOS)
                    Text("Height \(height)")
                    Button("-") { height = max(50, height - 50) }
                    Button("+") { height = min(350, height + 50) }
                    #else
                    Text("Height")
                    Slider(value: $height, in: 50...350)
                        .padding()
                    #endif
                }
            }
            .padding()
        }
        .navigationTitle("FUViewThatFits")
    }
}

struct FUViewThatFitsExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FUViewThatFitsExample()
        }
    }
}
#endif
