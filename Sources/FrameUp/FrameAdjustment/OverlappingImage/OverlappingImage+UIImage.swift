//
//  OverlappingImage+UIImage.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2022-01-25.
//

import SwiftUI

#if canImport(UIKit)
extension OverlappingImage {
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
}
#endif
