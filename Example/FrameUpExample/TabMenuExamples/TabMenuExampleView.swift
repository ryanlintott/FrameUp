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
    @State private var horizontalDistribution: TabMenuHorizontalDistribution = .automatic
    @State private var itemStyle: ExampleTabMenuItemStyleChoice = .automatic
    @State private var verticalBehavior: ToolbarVerticalBehaviorIfAvailable = .automatic
    @State private var tabMenuVerticalBehavior: TabMenuVerticalBehavior = .automatic
    @State private var verticalDistribution: TabMenuVerticalDistribution = .automatic

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
                Text("Item style")
                    .font(.caption)
                Picker("Item style", selection: $itemStyle) {
                    ForEach(ExampleTabMenuItemStyleChoice.allCases) { choice in
                        Text(choice.rawValue).tag(choice)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
                .padding(.horizontal)

                /// Apps can turn off the iPhone Duo's vertical bar. With `.system`, the tab menu then stays along the bottom.
                Text("System bar")
                    .font(.caption)
                Picker("System vertical bar", selection: $verticalBehavior) {
                    Text("Automatic").tag(ToolbarVerticalBehaviorIfAvailable.automatic)
                    Text("Disabled").tag(ToolbarVerticalBehaviorIfAvailable.disabled)
                }
                .pickerStyle(.segmented)
                    .fixedSize()
                    .padding(.horizontal)

                /// `.automatic` also uses a custom vertical bar on an iPhone in landscape. `.disabled` keeps the menu along the bottom everywhere.
                Text("Tab menu")
                    .font(.caption)
                Picker("Tab menu vertical behavior", selection: $tabMenuVerticalBehavior) {
                    Text("System").tag(TabMenuVerticalBehavior.system)
                    Text("Automatic").tag(TabMenuVerticalBehavior.automatic)
                    Text("Disabled").tag(TabMenuVerticalBehavior.disabled)
                }
                .pickerStyle(.segmented)
                .fixedSize()
                .padding(.horizontal)

                Text("Horizontal distribution")
                    .font(.caption)
                Picker("Tab menu horizontal distribution", selection: $horizontalDistribution) {
                    Text("Automatic").tag(TabMenuHorizontalDistribution.automatic)
                    Text("Equal").tag(TabMenuHorizontalDistribution.equal)
                    Text("Grouped").tag(TabMenuHorizontalDistribution.grouped(maxItemWidth: 90, spacing: 8))
                }
                .pickerStyle(.segmented)
                .fixedSize()
                .padding(.horizontal)

                Text("Vertical distribution")
                    .font(.caption)
                Picker("Tab menu vertical distribution", selection: $verticalDistribution) {
                    Text("Automatic").tag(TabMenuVerticalDistribution.automatic)
                    Text("Equal").tag(TabMenuVerticalDistribution.equal)
                    Text("Grouped").tag(TabMenuVerticalDistribution.grouped)
                }
                .pickerStyle(.segmented)
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
        /// Along the bottom on most screens, in the system's vertical bar on the iPhone Duo, and with `.automatic` in a custom vertical bar on an iPhone in landscape.
        .tabMenu(selection: $selection, items: TabMenuExample.items)
        .tabMenuItemStyle(ExampleTabMenuItemStyle(choice: itemStyle))
        .tabMenuHorizontalDistribution(horizontalDistribution)
        .tabMenuVerticalDistribution(verticalDistribution)
        .onTabMenuItemReselect("Reselect") {
            reselect = true
        }
        .onTabMenuItemDoubleTap("Double Tap") {
            doubleTap = true
        }
        .tabMenuVerticalBehavior(tabMenuVerticalBehavior)
        .toolbarVerticalBehaviorIfAvailable(verticalBehavior)
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

struct TabMenuViewExampleView_Previews: PreviewProvider {
    static var previews: some View {
        TabMenuExampleView()
    }
}
#endif
