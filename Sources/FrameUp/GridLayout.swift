//
//  GridLayout.swift
//  SwiftUITextDemo
//
//  Created by Ryan Lintott on 2021-06-11.
//

import SwiftUI

//struct SizePreferences<Item: Hashable>: PreferenceKey {
//    typealias Value = [Item: CGSize]
//
//    static var defaultValue: Value { [:] }
//
//    static func reduce(
//        value: inout Value,
//        nextValue: () -> Value
//    ) {
//        value.merge(nextValue()) { $1 }
//    }
//}
//
//struct Grid<Data: RandomAccessCollection, ElementView: View>: View where Data.Element: Hashable {
//    private let data: Data
//    private let itemView: (Data.Element) -> ElementView
//
//    @State private var preferences: [Data.Element: CGRect] = [:]
//
//    init(_ data: Data, @ViewBuilder itemView: @escaping (Data.Element) -> ElementView) {
//        self.data = data
//        self.itemView = itemView
//    }
//
//    var body: some View {
//        GeometryReader { geometry in
//            ZStack(alignment: .topLeading) {
//                ForEach(data, id: \.self) { item in
//                    itemView(item)
//                        .alignmentGuide(.leading) { _ in
//                            -preferences[item, default: .zero].origin.x
//                        }
//                        .alignmentGuide(.top) { _ in
//                            -preferences[item, default: .zero].origin.y
//                        }
//                        .anchorPreference(
//                            key: SizePreferences<Data.Element>.self,
//                            value: .bounds
//                        ) {
//                            [item: geometry[$0].size]
//                        }
//                }
//            }
//        }
//    }
//}

//struct GridLayout_Previews: PreviewProvider {
//    static let cards: [String] = [
//        "Lorem", "ipsum", "is", "placeholder", "text", "!!!"
//    ]
//    
//    static var previews: some View {
//        Grid(cards) { card in
//            Text(card)
//                .frame(width: 120, height: 120)
//                .background(Color.orange)
//                .cornerRadius(8)
//                .padding(4)
//        }
//    }
//}
