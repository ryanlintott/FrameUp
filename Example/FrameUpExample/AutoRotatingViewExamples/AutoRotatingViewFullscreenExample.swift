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
    
    /// Content that goes edge to edge alongside content that stays inside the safe area, with the container's corners drawn over it.
    func rotatingContent(_ geometry: AutoRotatingGeometryProxy) -> some View {
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
            .overlay {
                containerCorners(geometry)
                    .ignoresSafeArea()
            }
    }
    
    /// The container's corners as the content sees them, turned with it: the corner insets as blue rectangles, and the container shape's rounded corners as a yellow outline.
    @ViewBuilder
    func containerCorners(_ geometry: AutoRotatingGeometryProxy) -> some View {
        ZStack {
            /// The container shape, which AutoRotatingView turns with the content.
            ContainerRelativeShape()
                .strokeBorder(.yellow, lineWidth: 4)
            
            #if compiler(>=6.2)
            if #available(iOS 26, *) {
                let insets = geometry.containerCornerInsets
                Color.clear
                    .overlay(alignment: .topLeading) { cornerInset(insets.topLeading) }
                    .overlay(alignment: .topTrailing) { cornerInset(insets.topTrailing) }
                    .overlay(alignment: .bottomLeading) { cornerInset(insets.bottomLeading) }
                    .overlay(alignment: .bottomTrailing) { cornerInset(insets.bottomTrailing) }
            }
            #endif
            
            cornerRadii
        }
    }
    
    /// One corner inset, labelled with its size.
    func cornerInset(_ size: CGSize) -> some View {
        Rectangle()
            .fill(.blue.opacity(0.5))
            .overlay {
                if size.width >= 40 && size.height >= 40 {
                    Text("\(Int(size.width))×\(Int(size.height))")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                }
            }
            .frame(width: size.width, height: size.height)
    }
    
    /// The concentric corner radii of the content, listed in the middle of the screen.
    @ViewBuilder
    var cornerRadii: some View {
        #if canImport(SwiftUICore, _version: 8.0.84)
        if #available(iOS 27, *) {
            GeometryReader { proxy in
                if let radii = proxy.concentricCornerRadii {
                    VStack(alignment: .leading) {
                        Text("Corner radii")
                            .font(.caption.bold())
                        Text("topLeading \(radii.topLeading.formatted())")
                        Text("topTrailing \(radii.topTrailing.formatted())")
                        Text("bottomLeading \(radii.bottomLeading.formatted())")
                        Text("bottomTrailing \(radii.bottomTrailing.formatted())")
                    }
                    .font(.caption.monospaced())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        #endif
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
            Text("A fullscreen AutoRotatingView gives its content the whole screen in every orientation. The background ignores the safe area so it goes edge to edge, the dashed frame and the labels respect it, and the content turns around the centre of the screen without stepping or drifting.")
            
            Text("The blue rectangles are the container's corner insets and the yellow outline is its container shape, both turned with the content, so they should always sit on the screen's own corners and camera.")
            
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
            AutoRotatingView(allowedOrientations, animation: isAnimated ? .default : nil) { geometry in
                rotatingContent(geometry)
            }
            .overlay(alignment: .bottom) {
                controls
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
