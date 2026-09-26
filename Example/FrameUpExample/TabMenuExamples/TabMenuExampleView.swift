//
//  TabMenuExampleView.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2021-09-16.
//

import FrameUp
import SwiftUI

#if os(iOS)
struct TabMenuExampleView: View {
    @State private var selection = 0
    @State private var reselect: Bool = false
    @State private var doubleTap: Bool = false
    @State private var isCentered: Bool = false
    @State private var isVerticalBarEnabled: Bool = true

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
        .overlay(
            VStack {
                Toggle("Centred items", isOn: $isCentered)
                    .font(.body)
                    .fixedSize()
                    .padding(.horizontal)

                /// Apps can turn off the iPhone Duo's vertical bar, and the tab menu then stays along the bottom.
                Toggle("Vertical bar", isOn: $isVerticalBarEnabled)
                    .font(.body)
                    .fixedSize()
                    .padding(.horizontal)

                Spacer()

                if reselect {
                    Text("Reselect")
                }
                if doubleTap {
                    Text("DoubleTap")
                }
            }
                .animation(.default, value: reselect)
                .animation(.default, value: doubleTap)
        )
        .foregroundColor(.white)
        /// Along the bottom on most screens, and in the system's vertical bar on the iPhone Duo.
        .tabMenu(
            selection: $selection,
            items: TabMenuExample.items,
            isShowingName: true,
            itemPositioning: isCentered ? .centered(maxItemWidth: 90, spacing: 8) : .fill
        ) { isSelected in
            TabMenuExample.maskedView(isSelected: isSelected)
        } onReselect: {
            NamedAction("Reselect") {
                reselect = true
            }
        } onDoubleTap: {
            NamedAction("Double Tap") {
                doubleTap = true
            }
        }
        .modifier(VerticalBarBehaviorModifier(isEnabled: isVerticalBarEnabled))
        .onChange(of: reselect) { _ in
            if reselect {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    reselect = false
                }
            }
        }
        .onChange(of: doubleTap) { _ in
            if doubleTap {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    doubleTap = false
                }
            }
        }
        .navigationTitle("TabMenu")
    }
}

/// Turns the iPhone Duo's vertical bar off. Only iOS 27.1 has the option.
struct VerticalBarBehaviorModifier: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        #if canImport(SwiftUICore, _version: 8.0.85)
        if #available(iOS 27.1, *) {
            content
                .toolbarVerticalBehavior(isEnabled ? .automatic : .disabled)
        } else {
            content
        }
        #else
        content
        #endif
    }
}

struct TabMenuViewExampleView_Previews: PreviewProvider {
    static var previews: some View {
        TabMenuExampleView()
    }
}
#endif
