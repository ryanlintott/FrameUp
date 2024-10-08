//
//  WidgetFrameWidget.swift
//  WidgetFrameWidget
//
//  Created by Ryan Lintott on 2021-11-23.
//

import WidgetKit
import SwiftUI

struct WidgetFrameWidget: Widget {
    let kind: String = "WidgetFrameWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetFrameWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("WidgetFrame Example")
        .description("Example of WidgetFrame.")
    }
}

struct WidgetFrameWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        WidgetRelativeShapeExample()
    }
}

struct WidgetFrameWidget_Previews: PreviewProvider {
    static var previews: some View {
        WidgetFrameWidgetEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
