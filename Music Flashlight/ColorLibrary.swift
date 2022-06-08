//
//  ColorLibrary.swift
//  Music Flashlight
//
//  Created by Tim Baum on 06.06.22.
//

import Foundation
import SwiftUI

class ColorLibrary: ObservableObject {
    let colors: [Color] = [Color("f1"), Color("f2"), Color("f3"), Color("f4"), Color("f5"), Color("f6"), Color("f7"), Color("f8"), Color("f9")]
    var hue = Float(194.0/360.0) // starting value
    static let saturation = 0.82
    static let brightness = 1.0
    static let alpha = 1.0
    static let upperBoundary = Float(274.0/360.0)
    static let lowerBoundary = Float(32.0/360.0)
    @Published var color = UIColor(hue: CGFloat(Float(194.0/360.0)), saturation: saturation, brightness: brightness, alpha: alpha)

    func updateHue(frequencyValues: [Float]){
        //calculate lower and higher band
        let lowerBand = frequencyValues[0] + frequencyValues[1] + frequencyValues[2]
        var higherBand = Float(0)
        
        for i in stride(from: 3, to: frequencyValues.count, by: 1)
        {
            higherBand += frequencyValues[i]
        }
        
        if (lowerBand == 0) || (higherBand == 0) {
            return
        }
        
        var ratio = lowerBand/higherBand
        
        if ratio > 1 {
            ratio = 1 / ratio
        }
            
        
        //If higherBand is greater make value negative else leave positive
        var value = Float(ratio/300) //300 to make process
        if lowerBand < higherBand {
            value *= -1
        }
        print("Ratio " + String(value))
        print("Hue " + String(self.hue))

        //Update hue based on value
        if (self.hue + value) > ColorLibrary.upperBoundary {
            self.hue = ColorLibrary.upperBoundary
        } else if self.hue + value < ColorLibrary.lowerBoundary {
            self.hue = ColorLibrary.lowerBoundary
        } else {
            self.hue += value
        }
        color = UIColor(hue: CGFloat(hue), saturation: ColorLibrary.saturation, brightness: ColorLibrary.brightness, alpha: ColorLibrary.alpha)
    }
}
