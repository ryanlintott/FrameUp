//
//  WidgetRelativeShapeExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-05-10.
//

import FrameUp
import SwiftUI

#if os(iOS)
struct WidgetRelativeShapeExample: View {
    var body: some View {
        VStack {
            WidgetDemoFrame(.small) { size, cornerRadius in
                WidgetRelativeShapeDemo()
            }
            
            Text("To see this example, add the example FrameUp widget.")
        }
        .padding()
    }
}

struct WidgetRelativeShapeExample_Previews: PreviewProvider {
    static var previews: some View {
        WidgetRelativeShapeExample()
    }
}
#endif
