//
//  AutoRotatingViewFullscreenExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2026-09-10.
//

import FrameUp
import SwiftUI

#if os(iOS)
struct AutoRotatingViewFullscreenExample: View {
    @State private var isPresented: Bool = false
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
    
    /// Content that goes edge to edge alongside content that stays inside the safe area.
    var rotatingContent: some View {
        /// Respects the safe area so it should stay clear of the status bar and home indicator in every orientation.
        Rectangle()
            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
            .overlay(alignment: .top) {
                Text("Top")
            }
            .overlay(alignment: .bottom) {
                Text("Bottom")
            }
            .overlay(alignment: .leading) {
                Text("Leading")
            }
            .overlay(alignment: .trailing) {
                Text("Trailing")
            }
            .background {
                /// Ignores the safe area so it should reach every screen edge in every orientation.
                Color.pink
                    .ignoresSafeArea()
            }
            .font(.headline)
            .foregroundColor(.white)
    }
    
    /// Controls that stay with the screen instead of rotating with the content.
    var controls: some View {
        VStack {
            Text("Allowed Orientations")
                .font(.caption)
            
            HStack {
                Toggle("Portrait", isOn: $portrait)
                Toggle("Left", isOn: $landscapeLeft)
                Toggle("Right", isOn: $landscapeRight)
                Toggle("Upside Down", isOn: $portraitUpsideDown)
            }
            .toggleStyle(.button)
            .font(.caption)
            
            HStack {
                Toggle("Animation", isOn: $isAnimated)
                    .toggleStyle(.button)
                
                Button("Close") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("A fullscreen AutoRotatingView gives its content the whole screen in every orientation. The gradient ignores the safe area so it goes edge to edge, the dashed frame and the labels respect it, and the content turns around the centre of the screen without stepping or drifting.")
            
            Text("Rotate the device to an orientation the app does not support to see the view rotate on its own. Changing the allowed orientations rotates it without moving the device, which is the only way to see this in a simulator.")
            
            Button("Show Fullscreen") {
                isPresented = true
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .font(.callout)
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
        .navigationTitle("Fullscreen")
        .fullScreenCover(isPresented: $isPresented) {
            GeometryReader { outer in
                AutoRotatingView(allowedOrientations, animation: isAnimated ? .default : nil) {
                    rotatingContent
                                        .overlay {
                                            GeometryReader { proxy in
                                                let i = proxy.safeAreaInsets
                                                Text(String(format: "%.0f×%.0f\nT%.0f L%.0f B%.0f R%.0f",
                                                            proxy.size.width, proxy.size.height,
                                                            i.top, i.leading, i.bottom, i.trailing))
                                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                                    .padding(4)
                                                    .background(.black)
                                                    .foregroundStyle(.green)
                                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            }
                                        }
                }
                .overlay(alignment: .bottom) {
                    let i = outer.safeAreaInsets
                    Text(String(format: "container %.0f×%.0f  T%.0f L%.0f B%.0f R%.0f",
                                outer.size.width, outer.size.height,
                                i.top, i.leading, i.bottom, i.trailing))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .padding(4).background(.black).foregroundStyle(.yellow)
                }
                .overlay(alignment: .bottom) {
                    controls
                }
            }
        }
    }
}

struct AutoRotatingViewFullscreenExample_Previews: PreviewProvider {
    static var previews: some View {
        AutoRotatingViewFullscreenExample()
    }
}
#endif
