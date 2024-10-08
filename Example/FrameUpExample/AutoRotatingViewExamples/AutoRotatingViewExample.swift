//
//  AutoRotatingViewExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-04-05.
//

import FrameUp
import SwiftUI

#if os(iOS)
struct AutoRotatingViewExample: View {
    @State private var isAnimated: Bool = true
    @State private var portrait: Bool = true
    @State private var landscapeLeft: Bool = true
    @State private var landscapeRight: Bool = true
    @State private var portraitUpsideDown: Bool = true
    
    var allowedOrientations: [FUInterfaceOrientation] {
        zip(
            [
                portrait,
                landscapeLeft,
                landscapeRight,
                portraitUpsideDown
            ],
            [
                .portrait,
                .landscapeLeft,
                .landscapeRight,
                .portraitUpsideDown
            ]
        )
        .compactMap { $0 ? $1 : nil }
    }
    
    func face(text: String) -> some View {
        VStack {
            Image(systemName: "face.smiling")
                .resizable()
                .scaledToFit()
                .frame(height: 40)
            Button {
                print("clicked")
            } label: {
                Text(text)
            }
        }
    }
    
    var body: some View {
        VStack {
            AutoRotatingView(allowedOrientations, animation: isAnimated ? .default : nil) {
                VStack {
                    Image("FrameUp-logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 40)

                    Text("This view can auto-rotate to orientations the app does not support.")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(20)
            }
            
            VStack(alignment: .leading) {
                Toggle("Animation", isOn: $isAnimated)
                Section(header: Text("Allowed Orientations:").font(.headline)) {
                    Toggle("Portrait", isOn: $portrait)
                    Toggle("LandscapeLeft", isOn: $landscapeLeft)
                    Toggle("LandscapeRight", isOn: $landscapeRight)
                    Toggle("PortraitUpsideDown", isOn: $portraitUpsideDown)
                }
            }
            .padding()
        }
        .navigationTitle("AutoRotatingView")
    }
}

struct AutoRotatingViewExample_Previews: PreviewProvider {
    static var previews: some View {
        AutoRotatingViewExample()
    }
}
#endif
