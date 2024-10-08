//
//  TwoSidedViewExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-09-15.
//

import FrameUp
import SwiftUI

struct TwoSidedViewExample: View {
    enum ExampleAxis: Hashable, Identifiable {
        case horizontal
        case vertical
        case custom(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat)
        
        var id: Self { self }
        
        var axis: (x: CGFloat, y: CGFloat, z: CGFloat) {
            switch self {
            case .horizontal: (0, 1, 0)
            case .vertical: (1, 0, 0)
            case let .custom(x, y, z): (x, y, z)
            }
        }
    }
    
    @State private var angle: Angle = .degrees(0)
    @State private var exampleAxis: ExampleAxis = .custom(0.2, 0.8, 0)
    
    var backView: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.red)
            .overlay(Text("Down"))
    }
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.blue)
                .overlay(Text("Up"))
                /// This modifier creates the two-sided view by supplying a rotation and a back side.
                #if os(visionOS)
                .perspectiveRotationEffect(angle, axis: exampleAxis.axis, backsideFlip: .automatic) {
                    backView
                }
                #else
                .rotation3DEffect(angle, axis: exampleAxis.axis, perspective: 0.5, backsideFlip: .automatic) {
                    backView
                }
                #endif
                .padding()
            
            
            Picker("Axis", selection: $exampleAxis) {
                ForEach([ExampleAxis.horizontal, .vertical, .custom(1.0, 1.0, 0.0), .custom(0.7, 0.3, 0)]) { exampleAxis in
                    Text("\(String(describing: exampleAxis))")
                }
            }
            .pickerStyle(.segmented)
            
            Text("Change Rotation")
            HStack {
                ForEach([-360,-180,-90,-45,45,90,180,360], id: \.self) { i in
                    Button("\(i > 0 ? "+" : "")\(i)") {
                        withAnimation(.spring().speed(0.4)) {
                            angle += .degrees(Double(i))
                        }
                    }
                    .padding(1)
                }
            }
            .padding()
        }
    }
}

struct TwoSidedViewExample_Previews: PreviewProvider {
    static var previews: some View {
        TwoSidedViewExample()
    }
}
