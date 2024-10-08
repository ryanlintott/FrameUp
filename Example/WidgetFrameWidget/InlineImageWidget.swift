//
//  InlineImageWidget.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2023-09-04.
//

import WidgetKit
import SwiftUI

@available(iOS 16.0, *)
struct InlineImageWidget: Widget {
    let kind: String = "InlineImageWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            InlineImageWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Inline Image Example")
        .description("Example of an Inline image.")
        .supportedFamilies([.accessoryInline])
    }
}

@available(iOS 16.0, *)
struct InlineImageWidgetEntryView: View {
    var entry: Provider.Entry
    
    var body: some View {
        InlineImageExample()
    }
}

@available(iOS 16.0, *)
struct InlineImageWidget_Previews: PreviewProvider {
    static var previews: some View {
        InlineImageWidgetEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
    }
}
