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
    let colorLibrary = ColorLibrary()
    
    @State var active = false
    @State var threshold: Float = -30.0
    @State var strictMode = false
    @State var screenModeActivated = false
    @ObservedObject var audioSpectogram = AudioSpectrogram()
    
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
        ZStack{
            if screenModeActivated {
            AnimatedBackground()
                .ignoresSafeArea()
            } else {
                Color(.black)
                    .opacity(mic.volume > threshold ? calculateOpacity(volume: mic.volume, threshold: threshold) : 0.6)
                    .ignoresSafeArea()
            }
            
            VStack {
//                Text("Current volume: \(mic.volume, specifier: "%.0f")")
//                    .foregroundColor(.white)
                Button {
                    screenModeActivated.toggle()
                } label: {
                    Text("Screen Mode")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(10)
                        .background(RoundedRectangle(
                            cornerRadius: 10
                        )
                            .fill(Color(.black))
                            .shadow(radius: 5)
                        )
                }
                
                Spacer()
                if !screenModeActivated {
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
                } else {
                    Spacer()
                    HStack {
                        //MARK: Spectogram
                        ForEach(audioSpectogram.valuesP, id: \.self) {value in
                            Spacer()
                            RoundedRectangle(cornerRadius: 10)
                                .size(width: 8, height: CGFloat(value))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    Divider()
                        .padding(.horizontal)
                        .padding(.bottom)
                }
                
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
            }
        }
        .onChange(of: threshold) { treshold in
            mic.threshhold = threshold
        }
        .onChange(of: strictMode) { strictMode in
            mic.strictMode = strictMode
        }
        .background(Image("chromeBackground")
            .resizable()
            .ignoresSafeArea())
    }
}


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


struct AnimatedBackground: View {
    @State var start = UnitPoint(x: 0, y: -2)
    @State var end = UnitPoint(x: 4, y: 0)
    
    let timer = Timer.publish(every: 1, on: .main, in: .default).autoconnect()
    let colors = [Color(UIColor(red: 0.621, green: 0.75, blue: 1, alpha: 1)), Color(UIColor(red: 0.381, green: 0.933, blue: 0.668, alpha: 1)), Color(UIColor(red: 1, green: 0.688, blue: 0.688, alpha: 1))]
    
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
