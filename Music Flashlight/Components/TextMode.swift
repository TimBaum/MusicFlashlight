//
//  TextMode.swift
//  Music Flashlight
//
//  Created by Tim Baum on 09.06.22.
//

import Foundation
import SwiftUI

/**
 The text mode display (basically black color with the font). The font is adjusting to screen size, but I feel like there could be some more space
 */
struct TextMode: View {
    
    @Binding var displayedText: String
    
    var body: some View {
        VStack {
            Spacer()
            Text(displayedText)
                .font(.system(size: 1000))
                .fontWeight(.black)
                .rotationEffect(.degrees(90))
                .minimumScaleFactor(0.01)
                .lineLimit(1)
                .foregroundColor(.white)
                .scaledToFit()
            Spacer()
        }
    }
}

struct TextMode_Previews: PreviewProvider {
    static var previews: some View {
        TextMode(displayedText: .constant("I <3 "))
            .preferredColorScheme(.dark)
    }
}
