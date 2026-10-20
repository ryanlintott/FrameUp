//
//  NestedAutoRotatingViewExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2026-10-14.
//

import FrameUp
import SwiftUI

#if os(iOS)
/// A panel that stays still on the screen when the device turns, with a title on it that turns to stay upright.
///
/// The panel is an `AutoRotatingView` that only allows portrait. Its counter-rotation sets how it moves while the system turns the interface: carried by the system's animation, or held completely still. The title is a second `AutoRotatingView` inside it that allows the other orientations, so it turns with the device, and lays itself out from the `autoRotatingOrientation` environment value.
struct NestedAutoRotatingViewExample: View {
    @State private var isPresented: Bool = false
    @State private var counterRotation: FUCounterRotationStyle = .exampleDefault

    private var panel: some View {
        AutoRotatingView([.portrait], counterRotation: counterRotation) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.indigo)
                    .shadow(color: .black.opacity(0.6), radius: 16, x: 0, y: 8)

                AutoRotatingView([.landscapeLeft, .landscapeRight, .portrait]) {
                    NestedTitle()
                        .foregroundColor(.white)
                        .padding()
                        .border(.yellow, width: 2)
                }
                .padding(24)
            }
            .overlay(alignment: .top) {
                VStack(alignment: .trailing) {
                    Button("Close") {
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Picker("Counter Rotation", selection: $counterRotation) {
                        ForEach(FUCounterRotationStyle.exampleCases, id: \.self) { behavior in
                            Text("\(behavior)").tag(behavior)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
            }
            .padding(20)
            .background(Color.teal.ignoresSafeArea())
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("The panel only allows portrait, so when the device turns the system turns the interface underneath it. Choose how the panel moves during that turn: system keeps its orientation while the system's animation carries it, and hold keeps it completely still (iOS 17 and later). The title on the panel is a nested AutoRotatingView that allows portrait and both landscapes, so it turns with the device to stay upright, and stacks across the panel in landscape.")

            Button("Show Panel") {
                isPresented = true
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .font(.callout)
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
        .navigationTitle("Nested")
        .fullScreenCover(isPresented: $isPresented) {
            panel
        }
    }
}

/// A title, stacked down the panel in portrait and across it in landscape, read from the orientation of the `AutoRotatingView` it's in.
private struct NestedTitle: View {
    @Environment(\.autoRotatingOrientation) private var orientation
    
    var isLandscape: Bool {
        orientation == .landscapeLeft || orientation == .landscapeRight
    }

    var fulayout: AnyFULayout {
        isLandscape ? AnyFULayout(HStackFULayout(maxHeight: .infinity)) : AnyFULayout(VStackFULayout(maxWidth: .infinity))
    }
    
    @available(iOS 16, *)
    var layout: AnyLayout {
        isLandscape ? AnyLayout(HStackLayout()) : AnyLayout(VStackLayout())
    }

    var body: some View {
        if #available(iOS 16, *) {
            layout {
                bodyContent
            }
        } else {
            fulayout {
                bodyContent
            }
        }
    }
    
    @ViewBuilder
    var bodyContent: some View {
        Image(systemName: "rectangle.portrait.rotate")
            .font(.system(size: 60))
        titleText
    }

    var titleText: some View {
        VStack(spacing: 4) {
            Text("Title")
                .font(.largeTitle.bold())
            Text("This title turns to stay upright")
                .font(.caption)
            Text(orientation.map { "\($0)" } ?? "none")
                .font(.caption.monospaced())
        }
    }
}

#Preview {
    NavigationView {
        NestedAutoRotatingViewExample()
    }
}
#endif
