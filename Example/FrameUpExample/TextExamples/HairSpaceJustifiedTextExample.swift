//
//  HairSpaceJustifiedTextExample.swift
//  FrameUpExample
//
//  Created by Ryan Lintott on 2024-10-21.
//

import FrameUp
import SwiftUI

struct HairSpaceJustifiedTextExample: View {
    var body: some View {
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
}

#Preview {
    HairSpaceJustifiedTextExample()
}
