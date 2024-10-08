//
//  WidgetRelativeShapeDemo.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-10.
//

import SwiftUI

struct WidgetRelativeShapeDemo: View {
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "arrow.up.left")
                Spacer()
                Image(systemName: "arrow.up.right")
            }
            Spacer()
            Text("Widget Relative Shape (fixes iPad corner issues in iOS 15 and lower)")
            Spacer()
            HStack {
                Image(systemName: "arrow.down.left")
                Spacer()
                Image(systemName: "arrow.down.right")
            }
        }
        .padding(6)
        .foregroundColor(.white)
        .background(Color.blue)
    }
}

struct WidgetRelativeShapeDemo_Previews: PreviewProvider {
    static var previews: some View {
        WidgetRelativeShapeDemo()
    }
}
