//
//  RotationCentreExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2026-10-17.
//

import FrameUp
import SwiftUI

#if os(iOS)
/// An `AutoRotatingView` whose frame moves and changes size while its content turns, for checking the point the content turns around.
///
/// The screen is held still in device portrait, like a book cover, and the box inside it changes size and place with the system's turn, like a tab item in a bar that changes depth. The content inside turns to stay upright. The box (the `AutoRotatingView`'s frame) is outlined in blue and the content in red, each with a crosshair on its centre, so the two centres can be compared at every step of a turn.
///
/// Launch with `-FURotationCentreScreen` to show it at launch.
@available(iOS 17, *)
struct RotationCentreExample: View {
    var body: some View {
        AutoRotatingView([.portrait], systemRotation: .locked) {
            RotationCentreBoxes()
        }
        .ignoresSafeArea()
        .background(Color.black)
    }
}

/// How the box changes with the turn.
private enum RotationCentreMode: String, CaseIterable, Identifiable {
    case both = "Move + resize"
    case move = "Move"
    case resize = "Resize"
    case fixed = "Fixed"

    var id: Self { self }
}

@available(iOS 17, *)
private struct RotationCentreBoxes: View {
    @Environment(\.interfaceTurn) private var turn
    @Environment(\.autoRotatingHeldTurnAnimation) private var heldTurnAnimation
    @State private var mode: RotationCentreMode = .both

    /// The box's size: wide and short when the screen is upright, like a tab item along a bottom bar, and narrower and taller on its side.
    var boxSize: CGSize {
        switch mode {
        case .both, .resize: turn.isSideways ? CGSize(width: 100, height: 84) : CGSize(width: 100, height: 50)
        case .move, .fixed: CGSize(width: 100, height: 50)
        }
    }

    /// Where the box's centre is, as a fraction of the screen.
    var boxCentre: UnitPoint {
        switch mode {
        case .both, .move: turn.isSideways ? UnitPoint(x: 0.5, y: 0.85) : UnitPoint(x: 0.5, y: 0.7)
        case .resize, .fixed: UnitPoint(x: 0.5, y: 0.7)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.white

                AutoRotatingView([.portrait, .landscapeLeft, .landscapeRight]) {
                    VStack(spacing: 2) {
                        Image(systemName: "star")
                            .font(.title2)
                        Text("Favourites")
                            .font(.caption2)
                    }
                    .border(.red)
                    .overlay(Crosshair().stroke(.red, lineWidth: 1))
                }
                .border(.blue, width: 2)
                .overlay(Crosshair().stroke(.blue, lineWidth: 1))
                .frame(width: boxSize.width, height: boxSize.height)
                .position(x: proxy.size.width * boxCentre.x, y: proxy.size.height * boxCentre.y)
                /// The box moves and changes size in step with the system's turn.
                .animation(heldTurnAnimation, value: boxSize)
                .animation(heldTurnAnimation, value: boxCentre)

                Picker("Box", selection: $mode) {
                    ForEach(RotationCentreMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 60)
            }
        }
    }
}

/// Lines across the full width and height through the centre.
struct Crosshair: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
    }
}

@available(iOS 17, *)
#Preview {
    RotationCentreExample()
}
#endif
