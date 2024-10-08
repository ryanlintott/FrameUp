//
//  InlineImageExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-09-04.
//

import FrameUp
import SwiftUI
import WidgetKit


@available(iOS 16.0, *)
struct InlineImageExample: View {
    var body: some View {
        Label {
            Text("👈 Any Image")
        } icon: {
            AccessoryInlineImage("FrameUp-logo-alpha")
        }
    }
}

@available(iOS 16.0, *)
struct InlineImageExample_Previews: PreviewProvider {
    static var previews: some View {
        InlineImageExample()
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
    }
}
