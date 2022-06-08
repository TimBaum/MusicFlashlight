//
//  Control.swift
//  Music Flashlight
//
//  Created by Tim Baum on 08.06.22.
//

import Foundation
import SwiftUI

struct Controls: View {
    
    @Binding var screenMode: Bool
    @Binding var torchMode: Bool
    @Binding var textMode: Bool
    @Binding var threshold: Float
    @Binding var strictMode: Bool
    @Binding var displayedText: String
    
    func screenModeChanged(to: Bool) {
        if to == true {
            textMode = false
        }
    }
    
    func textModeChanged(to: Bool) {
        if to == true {
            screenMode = false
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Controls")
                .fontWeight(.bold)
                .foregroundColor(.white)
                .font(.title2)
            
            HStack {
                Tile(iconName: "rectangle.fill.on.rectangle.fill", title: "Screen", activated: $screenMode)
                Tile(iconName: "flashlight.on.fill", title: "Torch", activated: $torchMode)
                Tile(iconName: "text.bubble.fill", title: "Text", activated: $textMode)
            }
            //MARK: Section Torch
            if(torchMode){
                HStack{
                    Text("Sensitivity")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                VStack {
                    Slider(
                        value: $threshold,
                        in: -60...0
                    ){
                        Text("Speed")
                    } minimumValueLabel: {
                        Text("High")
                    } maximumValueLabel: {
                        Text("Low")
                    }
                    .foregroundColor(.white)
                }
                Toggle(isOn: $strictMode) {
                    Text("Strict Mode")
                        .foregroundColor(.white)
                }
            }
            if(textMode)
            {
                HStack{
                    Text("Displayed Text: ")
                        .foregroundColor(.white)
                    Spacer()
                    TextField("edit me", text: $displayedText)
                        .foregroundColor(.white)
                        
                }
            }        }
        .padding(10)
        .background(RoundedRectangle(
            cornerRadius: 10
        )
            .fill(Color("controlsBackground"))
            .shadow(radius: 1)
        )
        .padding(.horizontal)
    }
}

struct Tile: View {
    let iconName: String
    let title: String
    @Binding var activated: Bool
    
    var body: some View {
        Button {
            activated.toggle()
        } label: {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(activated ? .white : Color("disabledText"))
                Text(title)
                    .font(.headline)
                    .foregroundColor(activated ? .white : Color("disabledText"))
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(RoundedRectangle(
                cornerRadius: 10
            )
                .fill(activated ? .black : Color("disabledBlack"))
            )
        }
    }
}

struct ControlPreview_Previews: PreviewProvider {
    static var previews: some View {
        Controls(screenMode: .constant(true), torchMode: .constant(true), textMode: .constant(true), threshold: .constant(Float(30.0)), strictMode: .constant(true), displayedText: .constant("Hey"))
            .previewInterfaceOrientation(.portrait)
    }
}
