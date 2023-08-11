//
//  HairSpaceJustifiedText.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2022-11-15.
//
import SwiftUI

#if os(iOS)
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
        
        var characters = Array(String(self)).map({String($0)})
        var multiline = [characters.removeFirst()]
        var index = 0
        
        while !characters.isEmpty {
            let character = characters.removeFirst()
            
            let line = multiline[index] + character
            
            if line.size(using: font).width <= maxWidth {
                multiline[index] = line
            } else {
                multiline.append(character)
                index += 1
            }
        }
        return multiline
    }
    
    /// Returns an array of lines that fit the maximum width split at the last separator that fits.
    ///
    /// If a single word is larger than the maximum width, `splitMultilineByCharacter()` is used on that line.
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
                .map { $0.justifiedByHairSpaces(font: font, maxWidth: maxWidth) }
                .joined(separator: String(lineBreak))
        }
        
        let separator: Character = " "
        let hairSpace: String = "\u{200A}"
        
        let lines = splitMultiline(font: font, maxWidth: maxWidth)
        
        guard let last = lines.last else { return "" }
        
        let justifiedLines = lines
            .dropLast(justifyLastLine ? 0 : 1)
            .map { line in
                let words = line.split(separator: separator)
                guard words.count > 1 else { return words.joined() }
                let justifiedSeparator = String(hairSpace)
                var justifiedLine = words.joined(separator: justifiedSeparator)
                var hairSpaceCount = 0
                while justifiedLine.size(using: font).width < maxWidth {
                    hairSpaceCount += 1
                    justifiedLine += hairSpace
                }
                hairSpaceCount -= 1
                let (minCount, extraCount) = hairSpaceCount.quotientAndRemainder(dividingBy: words.count - 1)
                let spaces = Array(0..<words.count)
                    .map { i in
                        String.init(repeating: hairSpace, count: minCount) + (i < extraCount ? hairSpace : "")
                    }
                return zip(words, spaces)
                    .map {
                        String($0 + $1)
                    }
                    .joined()
                    .trimmingCharacters(in: .whitespaces)
            }
        
        return (justifiedLines + (justifyLastLine ? [] : [last]))
            .joined(separator: "\n")
    }
}

/// A SwiftUI-only method for efficiently presenting justifying text. This is particularly useful in a widget or other SwiftUI-only setting.
struct HairSpaceJustifiedText: View {
    let text: String
    let font: UIFont
    let justifyLastLine: Bool
    
    init(_ text: String, font: UIFont, justifyLastLine: Bool = false) {
        self.font = font
        self.text = text
        self.justifyLastLine = justifyLastLine
    }
    
    var body: some View {
        WidthReader { width in
            Text(text.justifiedByHairSpaces(font: font, maxWidth: width, justifyLastLine: justifyLastLine))
                .font(Font(font))
                .accessibilityLabel(Text(text)) /// Keep existing text to ensure VoiceOver works correctly.
        }
    }
}

struct HairSpaceJustifiedText_Previews: PreviewProvider {
    static var previews: some View {
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
        .padding()
    }
}
#endif
