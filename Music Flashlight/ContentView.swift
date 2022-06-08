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
    
    @State var active = false
    @State var threshold: Float = -30.0
    @State var strictMode = false
    @State var screenModeActivated = false
    @State var animationSides = Double(0)
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
            if screenModeActivated {
//                colorLibrary.colors[audioSpectogram.valuesP.firstIndex(of: audioSpectogram.valuesP.max()!) ?? 0]
                Color(colorLibrary.color)
                    .ignoresSafeArea()
                AnimatedBackground()
                    .ignoresSafeArea()
            }
            else {
            //White or black overlay
            Color(.black)
                .opacity(mic.volume > threshold ? calculateOpacity(volume: mic.volume, threshold: threshold) : 0.6)
                .ignoresSafeArea()
            }
            VStack {
                Button {
                    if screenModeActivated == false {
                        active = false
                        audioSpectogram.startRunning()
                    }
                    else {
                        audioSpectogram.stopRunning()
                    }
                    screenModeActivated.toggle()
                } label: {
                    Text("Screen Mode")
                        .foregroundColor(screenModeActivated ? .black : .white)
                        .font(.headline)
                        .padding(10)
                        .background(RoundedRectangle(
                            cornerRadius: 10
                        )
                            .fill(Color(screenModeActivated ? .white : .black))
                            .shadow(radius: 5)
                        )
                }
                
                Spacer()
                if !screenModeActivated {
                    //MARK: Flashlight Mode
                    Button {
                        self.active.toggle()
                        mic.toggleMonitoring()
                    } label: {
                        Image("Lightning")
                            .resizable()
                            .foregroundColor(active ? enabledColor : disabledColor)
                            .aspectRatio(contentMode: .fit)
                            .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.4), radius: 5, x: 0, y: 20)
                            .frame(height: mic.volume > threshold ? CGFloat(400 + 120 * calculateOffset(volume: mic.volume, threshold: threshold)) : 400)
                    }
                    Spacer()
                    Divider()
                        .padding(.horizontal)
                        .padding(.bottom)
                    
                    HStack{
                        Text("Sensitivity")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.leading)
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
                                .foregroundColor(.white)
                        } maximumValueLabel: {
                            Text("Low")
                                .foregroundColor(.white)
                        }
                        //                    Text("Threshold: \(threshold, specifier: "%.0f")db")
                        //                        .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    Toggle(isOn: $strictMode) {
                        Text("Strict Mode")
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                } else {
                    //MARK: Screen Mode
                    Example4(sides: $animationSides)
                        .frame(height: 250)
                    Spacer()
                    HStack {
                        //MARK: Spectogram
                        ForEach(audioSpectogram.valuesP, id: \.self) {value in
                            Spacer()
                            VStack{
                                RoundedRectangle(cornerRadius: 10)
                                    .size(width: 8, height: CGFloat(value))
                                    .foregroundColor(.white)
                            }
                            
                        }
                        Spacer()
                    }
                    .frame(height: 200)
                }
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
        //Show the image when screen mode not activated, else show no background
        .background(!screenModeActivated ? Image("chromeBackground")
            .resizable()
            .ignoresSafeArea() : nil)
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
