//
//  RotationDirectionExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2026-09-25.
//

import SwiftUI

/// The same `rotation3DEffect` in a left to right and a right to left layout, side by side, driven by one slider per axis.
///
/// The arrow is `arrow.up`, which SF Symbols doesn't mirror in right to left, so any difference between the two comes from the rotation.
struct RotationDirectionExample: View {
    @State private var xDegrees: Double = 0
    @State private var yDegrees: Double = 0
    @State private var zDegrees: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                panel("Left to right")
                    .environment(\.layoutDirection, .leftToRight)
                panel("Right to left")
                    .environment(\.layoutDirection, .rightToLeft)
            }

            VStack(alignment: .leading) {
                slider("x", value: $xDegrees)
                slider("y", value: $yDegrees)
                slider("z", value: $zDegrees)

                Button("Reset") {
                    xDegrees = 0
                    yDegrees = 0
                    zDegrees = 0
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .navigationTitle("Rotation Direction")
    }

    /// A slider for the angle of rotation about one axis.
    func slider(_ axis: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(axis): \(Int(value.wrappedValue))°")
                .font(.body.monospaced())
            Slider(value: value, in: -180...180, step: 1)
        }
    }

    func panel(_ title: String) -> some View {
        VStack {
            Text(title)
                .font(.headline)

            Image(systemName: "arrow.up")
                .font(.system(size: 60, weight: .bold))
                .frame(width: 120, height: 120)
                .background(.yellow)
                .rotation3DEffect(.degrees(xDegrees), axis: (x: 1, y: 0, z: 0))
                .rotation3DEffect(.degrees(yDegrees), axis: (x: 0, y: 1, z: 0))
                .rotation3DEffect(.degrees(zDegrees), axis: (x: 0, y: 0, z: 1))
                .frame(width: 170, height: 170)
                .background(.gray.opacity(0.2))
        }
    }
}

#Preview {
    NavigationView {
        RotationDirectionExample()
    }
}
