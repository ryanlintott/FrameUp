//
//  JustifiedTextExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-11-15.
//

import FrameUp
import SwiftUI
import WidgetKit

struct JustifiedTextExample: View {
    let text: String
    var words: Array<(offset: Int, element: String)> {
        Array(text.split(separator: " ").map(String.init).enumerated())
    }
    
    var body: some View {
        GeometryReader { proxy in
            HFlow(alignment: .topJustified, maxWidth: proxy.size.width) {
                ForEach(words, id: \.offset) { word in
                    Text(word.element)
                }
            }
        }
        .padding()
    }
}

struct JustifiedTextExample_Previews: PreviewProvider {
    static var previews: some View {
        JustifiedTextExample(text: "Hello World! Here is some long text that is justified using HFlow from FrameUp. It seems to work ok even with a bunch of text.")
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
