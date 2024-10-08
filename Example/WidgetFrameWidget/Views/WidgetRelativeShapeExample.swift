//
//  WidgetRelativeShape.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2021-11-24.
//

#if os(iOS)
import FrameUp
import SwiftUI
import WidgetKit

@available(iOS, obsoleted: 16, message: "This modifier is no longer needed")
struct WidgetRelativeShapeExample: View {
    var body: some View {
        WidgetRelativeShapeDemo()
            .clipShape(WidgetRelativeShape(.systemSmall))
            .background(
                ContainerRelativeShape()
                    .fill(.red)
            )
            .padding(1)
    }
}

@available(iOS, obsoleted: 16, message: "This modifier is no longer needed")
struct WidgetRelativeShape_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            if #available(iOS 16, *) {
                
            } else {
                // broken on iPads
                ContainerRelativeShape()
                    .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.red)
                    .overlay(
                        Text("Corner radius not correct on iPad widgets in iOS 15 and lower")
                    )
                    .padding(1)
            }
            
            // fixed on all devices
            WidgetRelativeShapeExample()
        }
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
#endif
