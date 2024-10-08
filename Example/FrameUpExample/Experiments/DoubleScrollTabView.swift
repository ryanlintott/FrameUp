//
//  DoubleScrollTabView.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-11-13.
//

import FrameUp
import SwiftUI

#if os(iOS)
enum DoubleScrollTab: Int, RawRepresentable, CaseIterable {
    case first
    case second
}

struct DoubleScrollTabViewExample: View {
    var body: some View {
        GeometryReader { proxy in
            DoubleScrollTabView(maxWidth: proxy.size.width)
        }
    }
}

struct DoubleScrollTabView: View {
    var items: [(Int, String)] {
        Array(1...200).map { ($0, "Item \($0)") }
    }
    
    @State private var scroll1: CGFloat = 0
    @State private var scroll2: CGFloat = 0
    @State private var headerOffset: CGFloat = 0
    @State private var tab: DoubleScrollTab = .first
    
    let maxWidth: CGFloat
    
    let minHeaderHeight: CGFloat = 50
    let maxHeaderHeight: CGFloat = 200
    var minHeaderOffset: CGFloat {
        minHeaderHeight - maxHeaderHeight
    }
    
    @State private var dragOffset: CGFloat = .zero
    @State private var predictedDragOffset: CGFloat = .zero
    @GestureState private var isDragging: Bool = false
    
    var tabOffset: CGFloat {
        maxWidth * CGFloat(tab.rawValue) - dragOffset
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 0) {
                SmartScrollView(showsIndicators: false, optionalScrolling: false, shrinkToFit: false) {
                    scrollContent
                        .background(Color.blue)
                } onScroll: { edgeInsets in
                    guard let newScroll1 = edgeInsets?.top else { return }
                    let scrollDifference = newScroll1 - scroll1
                    if newScroll1 < headerOffset, scrollDifference < 0, headerOffset > minHeaderOffset {
                        headerOffset += scrollDifference
                    } else if scrollDifference > 0, newScroll1 > headerOffset {
                        headerOffset += scrollDifference
                    }
                    scroll1 = newScroll1
                }
                .offset(y: min(0, max(headerOffset - scroll1, minHeaderOffset)))

                
                SmartScrollView(showsIndicators: false, optionalScrolling: false, shrinkToFit: false) {
                    scrollContent
                        .background(Color.red)
                } onScroll: { edgeInsets in
                    guard let newScroll2 = edgeInsets?.top else { return }
                    let scrollDifference = newScroll2 - scroll2
                    if newScroll2 < headerOffset, scrollDifference < 0, headerOffset > minHeaderOffset {
                        headerOffset += scrollDifference
                    } else if scrollDifference > 0, newScroll2 > headerOffset {
                        headerOffset += scrollDifference
                    }
                    scroll2 = newScroll2
                }
                .offset(y: min(0, max(headerOffset - scroll2, minHeaderOffset)))
            }
            .padding(.bottom, -maxHeaderHeight)
            .frame(width: maxWidth * 2, alignment: .leading)
            .offset(x: -tabOffset)
            .frame(width: maxWidth, alignment: .leading)
            .onChange(of: isDragging) { isDragging in
                if !isDragging {
                    onDragEnded()
                }
            }
            .gesture(drag)
            
            header
                .frame(height: maxHeaderHeight)
                .background(Color.gray.ignoresSafeArea(edges: .top).padding(.top, -headerOffset))
                .offset(y: headerOffset)
        }
        .overlay(debug, alignment: .bottom)
    }
    
    var header: some View {
        ZStack(alignment: .bottom) {
            Color.clear
            
            VStack {
                Spacer()
                
                Text("Header")
                    .font(.largeTitle)
                
                Text("This view is experimental")
                    .font(.subheadline)
                
                Spacer()
                
                TabMenu(selection: $tab.animation(.default), items: [
                    TabMenuItem(image: Image(systemName: "1.circle"), name: "First", tab: .first),
                    TabMenuItem(image: Image(systemName: "2.circle"), name: "Second", tab: .second)
                ]) { isSelected in
                    Group {
                        if isSelected {
                            Color.blue
                        } else {
                            Color.white
                        }
                    }
                }
            }
        }
    }
    
    var debug: some View {
        VStack {
            Text("scroll1: \(scroll1)")
            Text("scroll2: \(scroll2)")
            Text("headerOffset: \(headerOffset)")
        }
        .frame(maxWidth: .infinity)
        .background(Color.yellow.opacity(0.8))
    }
    
    var scrollContent: some View {
        VStack {
            ForEach(items, id: \.0) { (i, text) in
                Text(text)
                    .font(.title)
            }
        }
        .padding(.top, maxHeaderHeight)
        .frame(maxWidth: .infinity)
    }
    
    var drag: some Gesture {
        DragGesture(minimumDistance: 20)
            .updating($isDragging) { value, gestureState, transaction in
                gestureState = true
            }
            .onChanged { value in
                predictedDragOffset = value.predictedEndTranslation.width
                dragOffset = value.translation.width
            }
    }
    
    func onDragEnded() {
        let velocity = predictedDragOffset - dragOffset

        withAnimation(.spring()) {
            if velocity < 0 {
                tab = .second
            } else {
                tab = .first
            }
            dragOffset = .zero
            predictedDragOffset = .zero
        }
    }
}

struct DoubleScrollTabView_Previews: PreviewProvider {
    static var previews: some View {
        DoubleScrollTabViewExample()
    }
}
#endif
