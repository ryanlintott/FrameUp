//
//  TabMenuFullscreenExampleView.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2026-09-25.
//

import FrameUp
import SwiftUI

#if os(iOS)
struct TabMenuFullscreenExampleView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selection = 0
    @State private var isCentered = false
    @State private var isVerticalBarEnabled = false

    var body: some View {
        Group {
            switch selection {
            case 0:
                Color.blue
                    .overlay(Text("Info"))
            case 1:
                Color.red
                    .overlay(Text("Favourites"))
            case 2:
                Color.green
                    .overlay(Text("Categories"))
            case 3:
                Color.purple
                    .overlay(Text("About"))
            default:
                Color.white
            }
        }
        .font(.system(size: 30))
        .overlay(alignment: .top) {
            HStack {
                Toggle("Centred", isOn: $isCentered)
                Toggle("Vertical bar", isOn: $isVerticalBarEnabled)
                Button("Close", action: dismiss.callAsFunction)
            }
            .font(.body)
            .toggleStyle(.button)
            .buttonStyle(.bordered)
            .padding()
            .background(.ultraThinMaterial)
        }
        .foregroundColor(.white)
        .tabMenu(
            selection: $selection,
            items: TabMenuExample.items,
            isShowingName: true,
            itemPositioning: isCentered ? .centered(maxItemWidth: 90, spacing: 8) : .fill
        ) { isSelected in
            TabMenuExample.maskedView(isSelected: isSelected)
        }
        .modifier(VerticalBarBehaviorModifier(isEnabled: isVerticalBarEnabled))
    }
}
#endif
