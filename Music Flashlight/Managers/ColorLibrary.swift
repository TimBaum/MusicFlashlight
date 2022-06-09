//
//  ColorLibrary.swift
//  Music Flashlight
//
//  Created by Tim Baum on 06.06.22.
//

import Foundation
import SwiftUI

/**
 This class calculates the background color based on the obtained frequency values
 */
class ColorLibrary: ObservableObject {
    //Color values, hue is the changing value but saturation and brightness stay the same
    var hue = Float(194.0/360.0) // starting value
    static let saturation = 0.82
    static let brightness = 1.0
    static let alpha = 1.0
    //Boundaries for the hue value
    static let upperBoundary = Float(274.0/360.0)
    static let lowerBoundary = Float(32.0/360.0)
    //The color, that is getting displayed as the background
    @Published var color = UIColor(hue: CGFloat(Float(194.0/360.0)), saturation: saturation, brightness: brightness, alpha: alpha)
    
    /**
     move the hue value closer to the color, which is associated with the louder frequency (high or low in this case)
     */
    func updateHue(frequencyValues: [Float]){
        
        let value = calculateValueForHueChange(frequencyValues: frequencyValues)
        
        print("Ratio " + String(value))
        print("Hue " + String(self.hue))
        
        let newHue = self.hue + value
        
        //Update hue based on value and stop at boundaries
        if newHue > ColorLibrary.upperBoundary {
            self.hue = ColorLibrary.upperBoundary
        } else if newHue < ColorLibrary.lowerBoundary {
            self.hue = ColorLibrary.lowerBoundary
        } else {
            self.hue = newHue
        }
        //Update (and publish) color
        color = UIColor(hue: CGFloat(hue), saturation: ColorLibrary.saturation, brightness: ColorLibrary.brightness, alpha: ColorLibrary.alpha)
    }
    
    
    /**
     calculate the low and high bands and based on their ratio the value with which hue should be changed
     */
    private func calculateValueForHueChange(frequencyValues: [Float]) -> Float {
        //calculate lower and higher band
        let lowerBand = frequencyValues[0] + frequencyValues[1] + frequencyValues[2]
        var higherBand = Float(0)
        
        for i in stride(from: 3, to: frequencyValues.count, by: 1)
        {
            higherBand += frequencyValues[i]
        }
        
        if (lowerBand == 0) || (higherBand == 0) {
            return 0
        }
        
        var ratio = lowerBand/higherBand
        
        // if the ratio is higher than 1, we take the inverse to find the updating value
        if ratio > 1 {
            ratio = 1 / ratio
        }
        //-1 to
        ratio = 1 - ratio
        
        //When the lower band is higher, the hue update value should be negative (higher frequency ~ lower hue)
        if lowerBand < higherBand {
            ratio *= -1
        }
        let value = Float(ratio/300) //300 to make the process of updating the hue slower
        
        return value
    }
}
