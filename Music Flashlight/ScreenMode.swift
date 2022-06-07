//
//  ScreenMode.swift
//  Music Flashlight
//
//  Created by Tim Baum on 04.06.22.
//

import Foundation
import SwiftUI

struct ScreenMode: View {
        
    var body: some View {
        ZStack {
            Color(.black)
                .ignoresSafeArea()
        }
    }
}

struct ScreenModePreview: PreviewProvider {
    static var previews: some View {
        ScreenMode()
    }
}

