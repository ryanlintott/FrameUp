//
//  InnerHoldProbeExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2026-10-16.
//

import FrameUp
import SwiftUI

#if os(iOS)
/// A full-screen rectangle in an `AutoRotatingView`, for checking how it turns and holds on each screen of a foldable iPhone.
///
/// Launch with `-FUInnerHoldProbeScreen` to show it at launch. `-FUProbeAllowed portrait,landscapeLeft` sets the allowed orientations (default portrait), `-FUProbeBehavior lockedOrientation` the system rotation behaviour (default locked), and `-FUProbeNested YES` adds a nested `AutoRotatingView` that turns to stay upright. Turns and screen changes are logged:
/// `xcrun simctl spawn booted log stream --level info --predicate 'category == "InnerHoldProbe"'`
@available(iOS 17, *)
struct InnerHoldProbeExample: View {
    let allowedOrientations: [FUInterfaceOrientation] = {
        let names = UserDefaults.standard.string(forKey: "FUProbeAllowed")?.split(separator: ",").map(String.init) ?? ["portrait"]
        return FUInterfaceOrientation.allCases.filter { names.contains(String(describing: $0)) }
    }()
    let systemRotation: FUSystemRotationBehavior = UserDefaults.standard.string(forKey: "FUProbeBehavior") == "lockedOrientation" ? .lockedOrientation : .locked
    
    var body: some View {
        AutoRotatingView(allowedOrientations, systemRotation: systemRotation) {
            InnerHoldProbeRectangle()
                .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .background(Color.black)
        .statusBarHidden()
    }
}

/// A solid rectangle with a grid, so a squash or stretch shows, and a thick stripe on its top edge, so its orientation shows.
private struct InnerHoldProbeRectangle: View {
    @Environment(\.autoRotatingOrientation) private var orientation
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack(alignment: .top) {
                Color.blue
                
                Path { path in
                    for x in stride(from: 0, through: size.width, by: 50) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    for y in stride(from: 0, through: size.height, by: 50) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                
                Color.red
                    .frame(height: 60)
                    .overlay {
                        Text("TOP")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                    }
                
                VStack {
                    Text(orientation.map { String(describing: $0) } ?? "nil")
                    Text("\(Int(size.width)) × \(Int(size.height))")
                    if UserDefaults.standard.bool(forKey: "FUProbeNested") {
                        /// A nested view that allows every orientation but upside down, so it turns to stay upright on the held rectangle.
                        AutoRotatingView([.portrait, .landscapeLeft, .landscapeRight]) {
                            NestedProbeLabel()
                        }
                        .frame(width: 300, height: 300)
                    }
                }
                .font(.largeTitle.monospacedDigit().bold())
                .foregroundStyle(.white)
                .frame(maxHeight: .infinity)
            }
            .overlay(alignment: .topLeading) {
                /// A corner marker, to tell a half turn apart.
                Color.yellow
                    .frame(width: 80, height: 80)
                    .padding(.top, 60)
            }
        }
    }
}

/// An arrow that points to the top of the nested view, with its orientation.
private struct NestedProbeLabel: View {
    @Environment(\.autoRotatingOrientation) private var orientation
    
    var body: some View {
        VStack {
            Image(systemName: "arrow.up")
            Text(orientation.map { String(describing: $0) } ?? "nil")
        }
        .padding()
        .background(Color.green)
    }
}

@available(iOS 17, *)
#Preview {
    InnerHoldProbeExample()
}
#endif
