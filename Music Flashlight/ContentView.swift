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
    
    
    //Modes
    @State var torchMode = false
    @State var screenMode = false
    @State var textMode = false

    //Parameters for torch mode
    @State var threshold: Float = -30.0
    @State var strictMode = false
    
    //Parameter for animation in screen mode
    @State var animationSides = Double(0)
    
    //Text mode
    @State var displayText = "I <3 you"
    
    //Monitoring audio
    @ObservedObject private var mic = AudioMonitor()
    @ObservedObject var audioSpectogram = AudioSpectrogram()
    
    //Color for the background screen
    @ObservedObject var colorLibrary = ColorLibrary()
    
    /**
     calculate the offset for the size of the lightning
     */
    private func calculateOffset(volume: Float, threshold: Float) -> Float {
        return (1 + (-1) * volume / threshold)
    }
    
    /**
     calculate opacity of the overlay
     */
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
            if screenMode {
                //Background for screen mode
                Color(colorLibrary.color)
                    .ignoresSafeArea()
                AnimatedBackground() //small animated gradient overlay for more dynamic
                    .ignoresSafeArea()
                PolygonAnimation(sides: $animationSides)
                    .frame(height: 250)
            } else if (textMode) {
                //Background for text mode
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
                //Screen when nothing is selected
                LinearGradient(colors: [Color(red: 0.42, green: 0.43, blue: 0.96, opacity: 1), Color(red: 0.42, green: 0.43, blue: 0.96, opacity: 0.0)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }
            VStack {
                if (screenMode) {
                    //MARK: Screen Mode
                    HStack(alignment: .center) {
                        Spacer()
                        //Builds spectogram from the frequency values obtained
                        ForEach(audioSpectogram.valuesP, id: \.self) {value in
                            VStack{
                                withAnimation {
                                    RoundedRectangle(cornerRadius: 10)
                                        .size(width: 8, height: CGFloat(value))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    Spacer()
                } else if (textMode){
                    //MARK: Text Mode
                    TextMode(displayedText: $displayText)
                } else if (torchMode) {
                    //MARK: Flashlight Mode
                    Spacer()
                    //Image of lightning with modifiers
                    Image("Lightning")
                        .resizable()
                        .foregroundColor(torchMode ? enabledColor : disabledColor)
                        .aspectRatio(contentMode: .fit)
                        .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.4), radius: 5, x: 0, y: 20)
                        //dynamic size
                        .frame(height: mic.volume > threshold ? CGFloat(400 + 120 * calculateOffset(volume: mic.volume, threshold: threshold)) : 400)
                    Spacer()
                } else {
                    //Screen when nothing is selected
                    VStack{
                        Spacer()
                        Image("DalePlay")
                            .resizable()
                            .scaledToFit()
                            .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.4), radius: 5, x: 0, y: 20)
                            .padding(.horizontal)
                        Spacer()
                        Text("select your mode:")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.bottom)
                    }
                }
                //Controll component
                Controls(screenMode: $screenMode, torchMode: $torchMode, textMode: $textMode, threshold: $threshold, strictMode: $strictMode, displayedText: $displayText)
            }
        }
        .onChange(of: threshold) { treshold in
            //when the slider is changed, the threshold is updated for the torch
            mic.threshhold = threshold
        }
        .onChange(of: strictMode) { strictMode in
            mic.strictMode = strictMode
        }
        .onChange(of: audioSpectogram.valuesP) {values in
            //when the values chanve, the background color is updated
            colorLibrary.updateHue(frequencyValues: values)
            animationSides = Double((values.reduce(0, +) / 50))
        }
        .onChange(of: screenMode) {to in
            //when screen mode is changed, the listening for frequencies is started or ended and other concurrent modes are disabled
            if to {
                textMode = false
                audioSpectogram.startRunning()
            } else {
                audioSpectogram.stopRunning()
            }
        }
        .onChange(of: textMode) {to in
            //when text mode is enabled, screen mode needs to be disabled
            if to == true {
                screenMode = false
            }
        }
        .onChange(of: torchMode) {_ in
            //listening for loudness is (de)activated
            mic.toggleMonitoring()
        }
        //background image
        .background(Image("chromeBackground")
            .resizable()
            .ignoresSafeArea())
        .onAppear() {
            //Disable the device from going into lockscreen when using the app (since that would defeat the purpose)
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
}

//MARK: AnimatedBackground
/**
 slight overlay for the background screen mode
 */
struct AnimatedBackground: View {
    //The points where the gradient starts
    @State var start = UnitPoint(x: 0, y: -2)
    @State var end = UnitPoint(x: 4, y: 0)
    //Update timer
    let timer = Timer.publish(every: 1, on: .main, in: .default).autoconnect()
    //let colors = [Color(UIColor(red: 0.621, green: 0.75, blue: 1, alpha: 1)), Color(UIColor(red: 0.381, green: 0.933, blue: 0.668, alpha: 1)), Color(UIColor(red: 1, green: 0.688, blue: 0.688, alpha: 1))]
    //gradient colors
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

