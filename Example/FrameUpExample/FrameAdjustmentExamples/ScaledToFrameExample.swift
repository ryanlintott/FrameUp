//
//  ScaledToFrameExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2021-11-22.
//

import FrameUp
import SwiftUI

struct ScaledToFrameExample: View {
    @State private var width: CGFloat = 300
    @State private var height: CGFloat = 20
    @State private var scaleMode: ScaleMode = .both
    
    var body: some View {
        VStack {
            VStack {
                Spacer()
                
                Text("Unscaled")
                    .fixedSize()
                    .border(.blue)
                    .frame(width: width, height: height)
                    .border(.red)
                
                Spacer()
                
                Text("ScaledToFit")
                    .fixedSize()
                    .border(.blue)
                    .scaledToFit(width: width, height: height, scaleMode: scaleMode)
                    .frame(width: width, height: height)
                    .border(.red)
                
                Spacer()
                
                Text("ScaledToFill")
                    .fixedSize()
                    .border(.blue)
                    .scaledToFill(width: width, height: height, scaleMode: scaleMode)
                    .frame(width: width, height: height)
                    .border(.red)
                
                Spacer()
                
                Text("ScaledToFrame")
                    .fixedSize()
                    .border(.blue)
                    .scaledToFrame(width: width, height: height, contentMode: nil, scaleMode: scaleMode)
                    .frame(width: width, height: height)
                    .border(.red)
                
                Spacer()
            }
            .font(.system(size: 50))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack {
                #if os(tvOS)
                Text("Width \(width)")
                Button("-") { width = max(10, width - 10) }
                Button("+") { width = min(500, width + 10) }
                #else
                Text("Width")
                Slider(value: $width, in: 10...500)
                #endif
            }
            .padding(.horizontal)
            
            HStack {
                #if os(tvOS)
                Text("Height \(height)")
                Button("-") { height = max(10, height - 10) }
                Button("+") { height = min(100, height + 10) }
                #else
                Text("Height")
                Slider(value: $height, in: 10...100)
                #endif
            }
            .padding(.horizontal)
            
            Picker("Scale Mode", selection: $scaleMode) {
                ForEach(ScaleMode.allCases, id: \.self) { scaleMode in
                    Text(scaleMode.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
    }
}

struct ScaledToFrameExample_Previews: PreviewProvider {
    static var previews: some View {
        ScaledToFrameExample()
    }
}
