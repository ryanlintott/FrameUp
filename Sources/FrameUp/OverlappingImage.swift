//
//  OverlappingImage.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2020-12-11.
//

import SwiftUI

public struct OverlappingImage: View {
    let image: Image
    let axis: Axis
    let shift: CGFloat
    let newAspect: CGFloat
    
    var alignment: Alignment {
        axis == .horizontal ? .leading : .top
    }
    
    public init(_ image: Image, aspectRatio: CGFloat, top: CGFloat = 0, bottom: CGFloat = 0) {
        self.image = image
        self.axis = .vertical
        self.shift = top
        let newHeightPercent = 1 - top - bottom
        self.newAspect = aspectRatio / newHeightPercent
    }
    
    public init(_ image: Image, aspectRatio: CGFloat, left: CGFloat = 0, right: CGFloat = 0) {
        self.image = image
        self.axis = .horizontal
        self.shift = left
        let newWidthPercent = 1 - left - right
        self.newAspect = aspectRatio * newWidthPercent
    }
    
    public init(uiImage: UIImage, top: CGFloat = 0, bottom: CGFloat = 0) {
        let aspectRatio = uiImage.size.width / uiImage.size.height
        self.init(Image(uiImage: uiImage), aspectRatio: aspectRatio, top: top, bottom: bottom)
    }
    
    public init(uiImage: UIImage, left: CGFloat = 0, right: CGFloat = 0) {
        let aspectRatio = uiImage.size.width / uiImage.size.height
        self.init(Image(uiImage: uiImage), aspectRatio: aspectRatio, left: left, right: right)
    }
    
    public var body: some View {
        Color.clear
            .overlay(
                image
                    .resizable()
                    .alignmentGuide(.top) { d in
                        axis == .vertical ? shift * d.height : d[.top]
                    }
                    .alignmentGuide(.leading) { d in
                        axis == .horizontal ? shift * d.width : d[.leading]
                    }
                    .scaledToFill()
                , alignment: alignment
            )
            .aspectRatio(newAspect, contentMode: .fit)
            .flipsForRightToLeftLayoutDirection(false)
    }
}
