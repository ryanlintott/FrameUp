//
//  TwoSided3DViewExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2024-09-20.
//

#if os(visionOS)
import SwiftUI

struct TwoSided3DViewExample: View {
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
                .rotation3DEffect(angle, axis: exampleAxis.axis, backsideFlip: .automatic) {
                    backView
                }
                #if os(visionOS)
                .frame(maxWidth: 200, maxHeight: 200)
                .frame(maxDepth: 200, alignment: .center)
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

#Preview {
    TwoSided3DViewExample()
}
#endif
