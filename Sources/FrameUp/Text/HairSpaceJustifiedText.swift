//
//  HairSpaceJustifiedText.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-11-15.
//

import SwiftUI

#if canImport(UIKit)
extension StringProtocol {
    /// Returns the size of this string when printed in a single line in the specified font.
    /// - Parameter font: Font used when measuring size.
    /// - Returns: Size of this string when printed in a single line in the specified font.
    func size(using font: UIFont) -> CGSize {
        return (String(self) as NSString).size(withAttributes: [NSAttributedString.Key.font: font])
    }
    
    /// Returns an array of lines that fit the maximum width split at the last character break that fits.
    ///
    /// Useful when trying to print a word that doesn't fit on a single line. This does not handle hyphenation and will break words at whatever character fits.
    /// - Parameters:
    ///   - font: Font used when measuring size.
    ///   - maxWidth: Maximum width of a line of text.
    /// - Returns: An array of lines that fit the maximum width split at the last character break that fits.
    func splitMultilineByCharacter(font: UIFont, maxWidth: CGFloat) -> [String] {
        guard self.size(using: font).width > maxWidth else {
            return [String(self)]
        }
        
        var remaining = Substring(String(self))
        var multiline = [String]()
        
        while !remaining.isEmpty {
            /// Binary search for the longest prefix that fits rather than measuring again after every character.
            /// The lower bound is one character so a character wider than `maxWidth` still makes progress.
            var low = 1
            var high = remaining.count
            
            while low < high {
                let mid = low + (high - low + 1) / 2
                
                if remaining.prefix(mid).size(using: font).width <= maxWidth {
                    low = mid
                } else {
                    high = mid - 1
                }
            }
            
            multiline.append(String(remaining.prefix(low)))
            remaining = remaining.dropFirst(low)
        }
        return multiline
    }
    
    /// Returns an array of lines that fit the maximum width split at the last separator that fits.
    ///
    /// If a single word is larger than the maximum width, ``Swift/StringProtocol/splitMultilineByCharacter(font:maxWidth:)`` is used on that line.
    /// - Parameters:
    ///   - separator: Character that can be substituted for a line break.
    ///   - font: Font used when measuring size.
    ///   - maxWidth: Maximum width of a line of text.
    /// - Returns: An array of lines that fit the maximum width split at the last separator that fits.
    func splitMultiline(by separator: Character = " ", font: UIFont, maxWidth: CGFloat) -> [String] {
        guard self.size(using: font).width > maxWidth else {
            return [String(self)]
        }
        
        var parts = self.split(separator: separator)
        
        var multiline = [String]()
        
        while !parts.isEmpty {
            let part = String(parts.removeFirst())
            
            let line = [multiline.last, part].compactMap({$0}).joined(separator: String(separator))
            
            if !line.isEmpty && line.size(using: font).width <= maxWidth {
                if !multiline.isEmpty {
                    multiline[multiline.endIndex - 1] = line
                } else {
                    multiline.append(line)
                }
            } else {
                let wordParts = String(part).splitMultilineByCharacter(font: font, maxWidth: maxWidth)
                multiline += wordParts
            }
        }
        return multiline.map({String($0)})
    }
    
    /// Returns a string that will appear justified when displayed with the same specified font and maximum width.
    ///
    /// Spaces are replaced with varying numbers of hair space characters to adjust the spacing between each word. This creates a justified line but this text is not available for selection due to the large number of hairline characters instead of spaces.
    /// - Parameters:
    ///   - font: Font used when measuring size.
    ///   - maxWidth: Maximum width of a line of text.
    /// - Returns: A string that will appear justified when displayed with the same specified font and maximum width.
    func justifiedByHairSpaces(font: UIFont, maxWidth: CGFloat, justifyLastLine: Bool = false) -> String {
        let lineBreak: Character = "\n"
        if contains(lineBreak) {
            return split(separator: lineBreak, omittingEmptySubsequences: false)
                .map { $0.justifiedByHairSpaces(font: font, maxWidth: maxWidth, justifyLastLine: justifyLastLine) }
                .joined(separator: String(lineBreak))
        }
        
        let separator: Character = " "
        let hairSpace: String = "\u{200A}"
        
        let lines = splitMultiline(font: font, maxWidth: maxWidth)
        
        guard let last = lines.last else { return "" }
        
        /// Hair spaces are a fixed width in a given font so the number needed can be calculated from this single measurement.
        let hairSpaceWidth = hairSpace.size(using: font).width
        
        let justifiedLines = lines
            .dropLast(justifyLastLine ? 0 : 1)
            .map { line in
                let words = line.split(separator: separator)
                let gapCount = words.count - 1
                guard gapCount > 0 else { return words.joined() }
                /// Words joined by a single hair space is the narrowest this line can be.
                let baseWidth = words.joined(separator: hairSpace).size(using: font).width
                let availableWidth = maxWidth - baseWidth
                /// The extra hair spaces that fit are calculated rather than added one at a time and measured.
                /// Measuring is not an option as `size(using:)` ignores trailing whitespace on a line ending in right-to-left text, making that loop run until it has added over 10,000 hair spaces.
                let extraCount = hairSpaceWidth > 0 && availableWidth > 0 ? Int(availableWidth / hairSpaceWidth) : 0
                let (minCount, remainder) = extraCount.quotientAndRemainder(dividingBy: gapCount)
                /// Every gap gets the separating hair space plus an even share of the extras, with the remainder spread across the first gaps.
                let separators = (0..<gapCount)
                    .map { i in
                        String(repeating: hairSpace, count: 1 + minCount + (i < remainder ? 1 : 0))
                    }
                return zip(words, separators + [""])
                    .map {
                        String($0) + $1
                    }
                    .joined()
            }
        
        return (justifiedLines + (justifyLastLine ? [] : [last]))
            .joined(separator: " ")
    }
}

/// A SwiftUI-only method for efficiently presenting justifying text. This is particularly useful in a widget or other SwiftUI-only setting.
public struct HairSpaceJustifiedText: View {
    let text: String
    let font: UIFont
    let justifyLastLine: Bool
    
    public init(_ text: String, font: UIFont, justifyLastLine: Bool = false) {
        self.font = font
        self.text = text
        self.justifyLastLine = justifyLastLine
    }
    
    public var body: some View {
        WidthReader { width in
            Text(text.justifiedByHairSpaces(font: font, maxWidth: width, justifyLastLine: justifyLastLine))
                .font(Font(font))
                .accessibilityLabel(Text(text)) /// Keep existing text to ensure VoiceOver works correctly.
        }
    }
}

#Preview {
    VStack {
        /// Example of Text with mixed LTR and RTL text.
        Text("This ثم كلا ارتكبها إستيلاء البولندي, احداث نتيجة بالرّدأسر بـ.ثموصل جديدة  aslkasjdf والكساد. ان مكثّفة العالم الهادي أضف, مما مع انذار")
            .font(.system(size: 16).bold())
        
        /// Example of HairSpaceJustified with the same mixed LTR and RTL text.
        HairSpaceJustifiedText(
            // Arabic for "Hello, World"
            "This ثم كلا ارتكبها إستيلاء البولندي, احداث نتيجة بالرّدأسر بـ.ثموصل جديدة  aslkasjdf والكساد. ان مكثّفة العالم الهادي أضف, مما مع انذار",
            font: .boldSystemFont(ofSize: 16),
            justifyLastLine: false
        )
        
        HairSpaceJustifiedText(
        """
        This is a bunch of text justified by hair spaces. SwiftUI doesn't have a way of justifying text so this view swaps out all spaces with varying numbers of hair spaces to adjust each line and make it appear justified.
        The last line of a paragraph is not justified by default but it can be by parameter.
        Line breaks continue to work as expected.
        
        Multiple line breaks remain but       multiple spaces are condensed into a single space or line break.
        
        If you have a veryLongWordThatWillNotFitOnASingleLineItWillBeBrokenAtTheLastCharacterThatFits
        
        Words are not hyphenated.
        
        UIFont must be used as that is how the text width is calculated.
        """,
        font: .boldSystemFont(ofSize: 16),
        justifyLastLine: false
        )
    }
    .padding()
}
#endif
