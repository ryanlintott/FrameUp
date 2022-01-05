//
//  OverlappingImage.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2020-12-11.
//

import SwiftUI

/// An image view that can overlap content on the edges of its frame.
///
/// Image can overlap either on the vertical or horizontal axis but not both.
///
/// Be sure to consider spacing and use zIndex to place the image in front or behind content.
///
///     VStack(spacing: 0) {
///         Text("Overlapping Image")
///             .font(.system(size: 50))
///
///         OverlappingImage(Image(systemName: "star.square"), aspectRatio: 1.0, top: 0.1, bottom: 0.25)
///             .padding(.horizontal, 50)
///             .zIndex(1)
///
///         Text("The image above will overlap content above and below.")
///             .padding(20)
///     }
///
public struct OverlappingImage: View {
    let image: Image
    let axis: Axis
    let shift: CGFloat
    let newAspect: CGFloat
    
    var alignment: Alignment {
        axis == .horizontal ? .leading : .top
    }
    
    /// Creates an image view that overlaps content at the edges of its frame
    /// - Parameters:
    ///   - image: Image that will overlap content.
    ///   - aspectRatio: Aspect ratio of supplied image.
    ///   - top: Overlap percent at top edge.
    ///   - bottom: Overlap percent at bottom edge.
    public init(_ image: Image, aspectRatio: CGFloat, top: CGFloat = 0, bottom: CGFloat = 0) {
        self.image = image
        self.axis = .vertical
        self.shift = top
        let newHeightPercent = 1 - top - bottom
        self.newAspect = aspectRatio / newHeightPercent
    }
    
    /// Creates an image view that overlaps content at the edges of its frame
    /// - Parameters:
    ///   - image: Image that will overlap content.
    ///   - aspectRatio: Aspect ratio of supplied image.
    ///   - left: Overlap percent at left edge.
    ///   - right: Overlap percent at right edge.
    public init(_ image: Image, aspectRatio: CGFloat, left: CGFloat = 0, right: CGFloat = 0) {
        self.image = image
        self.axis = .horizontal
        self.shift = left
        let newWidthPercent = 1 - left - right
        self.newAspect = aspectRatio * newWidthPercent
    }
    
    /// Creates an image view that overlaps content at the edges of its frame
    /// - Parameters:
    ///   - uiImage: Image that will overlap content.
    ///   - top: Overlap percent at top edge.
    ///   - bottom: Overlap percent at bottom edge.
    public init(uiImage: UIImage, top: CGFloat = 0, bottom: CGFloat = 0) {
        self.init(Image(uiImage: uiImage), aspectRatio: uiImage.size.aspectRatio, top: top, bottom: bottom)
    }
    
    /// Creates an image view that overlaps content at the edges of its frame
    /// - Parameters:
    ///   - uiImage: Image that will overlap content.
    ///   - left: Overlap percent at left edge.
    ///   - right: Overlap percent at right edge.
    public init(uiImage: UIImage, left: CGFloat = 0, right: CGFloat = 0) {
        self.init(Image(uiImage: uiImage), aspectRatio: uiImage.size.aspectRatio, left: left, right: right)
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
