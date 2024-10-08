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
    @State private var maxWidth: CGFloat = 200
    @State private var maxHeight: CGFloat = 200
    
    @State private var fitHoriztonal: Bool = true
    @State private var fitVertical: Bool = true
    
    var fuViewThatFits: FUViewThatFits {
        switch (fitVertical, fitHoriztonal) {
        case (true, true):
            return FUViewThatFits(maxWidth: maxWidth, maxHeight: maxHeight)
        case (true, false):
            return FUViewThatFits(maxHeight: maxHeight)
        case (false, true):
            return FUViewThatFits(maxWidth: maxWidth)
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
            .frame(width: maxWidth, height: maxHeight)
            .border(Color.red)
            
            Spacer()
            
            VStack {
                Toggle("Fit Horizontal", isOn: $fitHoriztonal)
                HStack {
                    #if os(tvOS)
                    Text("Max Width \(maxWidth)")
                    Button("-") { maxWidth = max(50, maxWidth - 50) }
                    Button("+") { maxWidth = min(350, maxWidth + 50) }
                    #else
                    Text("Max Width")
                    Slider(value: $maxWidth, in: 50...350)
                        .padding()
                    #endif
                }
                
                Toggle("Fit Vertical", isOn: $fitVertical)
                HStack {
                    #if os(tvOS)
                    Text("Max Height \(maxHeight)")
                    Button("-") { maxHeight = max(50, maxHeight - 50) }
                    Button("+") { maxHeight = min(350, maxHeight + 50) }
                    #else
                    Text("Max Height")
                    Slider(value: $maxHeight, in: 50...350)
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
