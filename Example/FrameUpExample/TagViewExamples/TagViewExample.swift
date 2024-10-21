//
//  TagViewExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2021-09-15.
//

import FrameUp
import SwiftUI

@available(swift, deprecated: 6.0, message: "This view may crash with Swift 6 strict concurrency due to unsafe thread jumping. Use HFlowLayout instead.")
struct TagViewExample: View {
    let elements = ["Thing", "Another", "Test", "Short", "Long Text is Long", "More", "Cool Tag"]
    
    var body: some View {
        TagView(elements: elements) { element in
            Text(element)
                .foregroundColor(.white)
                .padding(10)
                .background(Color.blue)
                .clipShape(Capsule())
                .padding(2)
        }
        .padding(2)
        .background(Color.gray)
        .navigationTitle("TagView")
    }
}

@available(swift, deprecated: 6.0, message: "This view may crash with Swift 6 strict concurrency due to unsafe thread jumping. Use HFlowLayout instead.")
struct TagViewExample_Previews: PreviewProvider {
    static var previews: some View {
        TagViewExample()
    }
}
