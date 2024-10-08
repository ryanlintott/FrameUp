//
//  TabMenuExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2021-09-15.
//

import FrameUp
import SwiftUI

#if os(iOS)
struct TabMenuExample: View {
    @Binding var selection: Int
    let onReselect: (() -> Void)?
    let onDoubleTap: (() -> Void)?
    
    internal init(selection: Binding<Int>, onReselect: (() -> Void)? = nil, onDoubleTap: (() -> Void)? = nil) {
        self._selection = selection
        self.onReselect = onReselect
        self.onDoubleTap = onDoubleTap
    }
    
    let items = [
        TabMenuItem(icon: AnyView(Circle().stroke().overlay(Text("i"))), name: "Info", tab: 0),
        TabMenuItem(image: Image(systemName: "star"), name: "Favourites", tab: 1),
        TabMenuItem(image: Image(systemName: "bookmark"), name: "Categories", tab: 2),
        TabMenuItem(image: Image(systemName: "books.vertical"), name: "About", tab: 3)
    ]

    var body: some View {
        TabMenu(selection: $selection, items: items, isShowingName: true) { isSelected in
            Group {
                if isSelected {
                    Color.accentColor
                } else {
                    Color(.secondaryLabel)
                }
            }
        } onReselect: {
            NamedAction("Reselect") {
                onReselect?()
                print("TabMenu item \(selection) reselected")
            }
        } onDoubleTap: {
            NamedAction("Double Tap") {
                onDoubleTap?()
                print("TabMenu item \(selection) doubletapped")
            }
        }
    }
}

struct DefaultTabView: View {
    @Binding var selection: Int
    
    var body: some View {
        TabView(selection: $selection) {
            Color.blue
                .tabItem {
                    Image(systemName: "globe")
                    Text("Info")
                }
                .tag(0)
            
            Color.white
                .tabItem {
                    Image(systemName: "star")
                    Text("Favourites")
                }
                .tag(1)
            
            Color.white
                .tabItem {
                    Image(systemName: "bookmark")
                    Text("Categories")
                }
                .tag(2)
            
            Color.white
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("About")
                }
                .tag(3)
        }
    }
}

struct TabMenuExample_Previews: PreviewProvider {
    static var previews: some View {
        TabMenuExample(selection: .constant(0))
            .previewLayout(.sizeThatFits)
        
        ZStack {
            // Default SwiftUI TabView for comparison
            DefaultTabView(selection: .constant(0))
            
            VStack(spacing: 0) {
                Color.red.opacity(0.5)
                
                TabMenuExample(selection: .constant(0))
            }
        }
    }
}
#endif
