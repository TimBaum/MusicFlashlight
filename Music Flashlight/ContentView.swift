//
//  ContentView.swift
//  Music Flashlight
//
//  Created by Tim Baum on 28.04.22.
//

import SwiftUI
import Foundation

let enabledColor = Color(.yellow)
let disabledColor = Color(.gray)

struct ContentView: View {
    
    @ObservedObject private var mic = AudioMonitor()
    
    @State var torchMode = false
    @State var threshold: Float = -30.0
    @State var strictMode = false
    @State var screenMode = false
    @State var animationSides = Double(0)
    
    @State var textMode = false
    @State var displayText = "I <3 you"
    
    @ObservedObject var audioSpectogram = AudioSpectrogram()
    @ObservedObject var colorLibrary = ColorLibrary()
    
    private func calculateOffset(volume: Float, threshold: Float) -> Float {
        return (1 + (-1) * volume / threshold)
    }
    private func calculateOpacity(volume: Float, threshold: Float) -> Double {
        let level = Double(calculateOffset(volume: mic.volume, threshold: threshold)) * 4 //find a suiting level of brightness
        if level >= 0.6 {
            return 0.6
        } else if  level <= 0.1 {
            return 0.1
        }
        return level
    }
    
    var body: some View {
        ZStack {
            //Background for screen mode
            if screenMode {
                //                colorLibrary.colors[audioSpectogram.valuesP.firstIndex(of: audioSpectogram.valuesP.max()!) ?? 0]
                Color(colorLibrary.color)
                    .ignoresSafeArea()
                AnimatedBackground()
                    .ignoresSafeArea()
            } else if (textMode) {
                Color(.black)
                    .ignoresSafeArea()
            }
            else if (torchMode) {
                //White or black overlay
                Color(.black)
                    .opacity(mic.volume > threshold ? calculateOpacity(volume: mic.volume, threshold: threshold) : 0.6)
                    .ignoresSafeArea()
            }
            else {
                LinearGradient(colors: [Color(red: 0.42, green: 0.43, blue: 0.69, opacity: 1), Color(red: 0.42, green: 0.43, blue: 0.69, opacity: 0.2)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }
            VStack {
                Spacer()
                if (screenMode) {
                    //MARK: Screen Mode
                    Example4(sides: $animationSides)
                        .frame(height: 250)
                    Spacer()
                    HStack {
                        ForEach(audioSpectogram.valuesP, id: \.self) {value in
                            Spacer()
                            VStack{
                                withAnimation {
                                    RoundedRectangle(cornerRadius: 10)
                                        .size(width: 8, height: CGFloat(value))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        Spacer()
                    }
                    .frame(height: 200)
                } else if (textMode){
                    //MARK: Text Mode
                    TextMode(displayedText: $displayText)
                } else if (torchMode) {
                    //MARK: Flashlight Mode
                    Image("Lightning")
                        .resizable()
                        .foregroundColor(torchMode ? enabledColor : disabledColor)
                        .aspectRatio(contentMode: .fit)
                        .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.4), radius: 5, x: 0, y: 20)
                        .frame(height: mic.volume > threshold ? CGFloat(400 + 120 * calculateOffset(volume: mic.volume, threshold: threshold)) : 400)
                    Spacer()
                }
                Controls(screenMode: $screenMode, torchMode: $torchMode, textMode: $textMode, threshold: $threshold, strictMode: $strictMode, displayedText: $displayText)
            }
        }
        .onChange(of: threshold) { treshold in
            mic.threshhold = threshold
        }
        .onChange(of: strictMode) { strictMode in
            mic.strictMode = strictMode
        }
        .onChange(of: audioSpectogram.valuesP) {values in
            colorLibrary.updateHue(frequencyValues: values)
            animationSides = Double((values.reduce(0, +) / 50))
        }
        .onChange(of: screenMode) {to in
            if to {
                textMode = false
                audioSpectogram.startRunning()
            } else {
                audioSpectogram.stopRunning()
            }
        }
        .onChange(of: textMode) {to in
            if to == true {
                screenMode = false
            }
        }
        .onChange(of: torchMode) {_ in
            mic.toggleMonitoring()
        }
        //Show the image when screen mode not activated, else show no background
        .background(Image("chromeBackground")
            .resizable()
            .ignoresSafeArea())
        .onAppear() {
            //Disable the device from going into lockscreen when using the app
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
}

//MARK: Bar View

struct BarView: View {
    // 1
    var value: CGFloat
    
    var body: some View {
        ZStack {
            // 2
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(gradient: Gradient(colors: [.purple, .blue]),
                                     startPoint: .top,
                                     endPoint: .bottom))
            // 3
                .frame(width: (UIScreen.main.bounds.width - CGFloat(1) * 4) / CGFloat(1), height: value)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//MARK: AnimatedBackground
struct AnimatedBackground: View {
    @State var start = UnitPoint(x: 0, y: -2)
    @State var end = UnitPoint(x: 4, y: 0)
    
    let timer = Timer.publish(every: 1, on: .main, in: .default).autoconnect()
    //let colors = [Color(UIColor(red: 0.621, green: 0.75, blue: 1, alpha: 1)), Color(UIColor(red: 0.381, green: 0.933, blue: 0.668, alpha: 1)), Color(UIColor(red: 1, green: 0.688, blue: 0.688, alpha: 1))]
    let colors = [Color("gray1"),Color("gray2"),Color("gray3"),Color("gray4")]
    
    var body: some View {
        
        LinearGradient(gradient: Gradient(colors: colors), startPoint: start, endPoint: end)
            .animation(Animation.easeInOut(duration: 6).repeatForever())
            .onReceive(timer, perform: { _ in
                
                self.start = UnitPoint(x: 4, y: 0)
                self.end = UnitPoint(x: 0, y: 2)
                self.start = UnitPoint(x: -4, y: 20)
                self.start = UnitPoint(x: 4, y: 0)
            })
    }
}

//colorLibrary.colors[audioSpectogram.valuesP.firstIndex(of: audioSpectogram.valuesP.max()!) ?? 0]

