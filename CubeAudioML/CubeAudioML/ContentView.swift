import SwiftUI
import AVFoundation
import SoundAnalysis

// source: https://www.avanderlee.com/swiftui/conditional-view-modifier/
extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

import SwiftUI
import Accelerate
import AVFoundation
import SoundAnalysis

class Manager: NSObject, SNResultsObserving, ObservableObject {
    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult else { return }
        if result.classification(forIdentifier: "cube")!.confidence > 0.6 {
            
        }
    }
    
    private let audioEngine = AVAudioEngine()
    private var soundClassifier = CubeSoundClassifier()
    var streamAnalyzer: SNAudioStreamAnalyzer!
    
    
    private var averagePwrForCh0: Float = 0
    private var averagePwrForCh1: Float = 0
    private let LEVEL_LOPASS_TRIG: Float32 = 0.3
    
    
    private func startAudio() {
        audioEngine.prepare()
        try! audioEngine.start()
    }
    
    private func scaledPower(power: Float) -> Float {
        guard power.isFinite else {
            return 0.0
        }
        
        let minDb: Float = -80
        
        if power < minDb {
            return 0.0
        } else if power >= 1.0 {
            return 1.0
        } else {
            return (abs(minDb) - abs(power)) / abs(minDb)
        }
    }
    
    private func prepare() {
        let inputNode = audioEngine.inputNode
        let recFmt = inputNode.outputFormat(forBus: 0)
        streamAnalyzer = SNAudioStreamAnalyzer(format: recFmt)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recFmt) {
            [unowned self] (buffer, when) in
            DispatchQueue.global(qos: .userInitiated).async {
                self.streamAnalyzer.analyze(buffer, atAudioFramePosition: when.sampleTime)
                
                NSLog("here")
                
                guard let channelData = buffer.floatChannelData else {
                    return
                }
                
                let channelDataValue = channelData.pointee
                
                let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride).map{ channelDataValue[$0] }
                
                let rms = sqrt(channelDataValueArray.map {
                    return $0 * $0
                }
                                .reduce(0, +) / Float(buffer.frameLength))
                
                let avgPwr = 20 * log10(rms)
                
                let meterLevel = self.scaledPower(power: avgPwr)
                NSLog("meter is at \(meterLevel)")
            }
        }
        startAudio()
    }
    
    private func createReq() {
        let req = try! SNClassifySoundRequest(mlModel: soundClassifier.model)
        try! streamAnalyzer.add(req, withObserver: self)
    }
    
    func start() {
        prepare()
        createReq()
    }
}


struct ContentView: View {
    @StateObject var manager = Manager()
    
    var body: some View {
        VStack {
            Button("start") {
                manager.start()
            }
            
            
            
            let data: [Double] = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.5, 0.7, 0.3, 0.1, 0.2, 0.8, 0.7, 0.3, 0.3, 0.1, 0.2, 0.3, 0.4, 0.5, 0.2, 0.1, 0.6, 0.3, 0.5, 0.6, 0.3, 0.3, 0.2, 0.1]
            
            HStack {
                ForEach(data.suffix(20), id: \.self) { datum in
                    Capsule()
                        .fill(Color.black)
                        .frame(height: 100*datum)
                }
            }
            .padding()
            
            
            
        }
    }
}

struct TimerScreen: View {
    @StateObject var manager = Manager()
    
    @Namespace var namespace
    
    @State var showResult: Bool = false
    
    let greenColor: Color = Color(red: 33/256, green: 193/256, blue: 76/256)
    
    var body: some View {
        ZStack {
            if !showResult {
                LinearGradient(gradient: Gradient(colors: [Color(red: 109/256, green: 134/256, blue: 247/256), Color(red: 69/256, green: 98/256, blue: 234/256)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                    .matchedGeometryEffect(id: "bg", in: namespace)
            } else {
                Color(red: 230/255, green: 235/255, blue: 1)
                    .ignoresSafeArea()
                
                HStack {
                    VStack {
                        Button {
                            withAnimation(.spring()) {
                                showResult = false
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color(red: 109/256, green: 134/256, blue: 247/256))
                                
                                Text("Back")
                                    .foregroundColor(Color(red: 109/256, green: 134/256, blue: 247/256))
                            }
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 28)
                
                
                VStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(LinearGradient(gradient: Gradient(colors: [Color(red: 109/256, green: 134/256, blue: 247/256), Color(red: 69/256, green: 98/256, blue: 234/256)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(height: 145)
                        .shadow(color: Color(red: 69/256, green: 98/256, blue: 234/256).opacity(0.6), radius: 12, x: 0, y: 3)
                        .matchedGeometryEffect(id: "bg", in: namespace)
                        .ignoresSafeArea()
                        .padding(.horizontal, 28)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(LinearGradient(gradient: Gradient(colors: [Color(red: 109/256, green: 134/256, blue: 247/256), Color(red: 69/256, green: 98/256, blue: 234/256)]), startPoint: .topLeading, endPoint: .bottomTrailing)).opacity(0.6)
                            .frame(height: 110)
                            .padding(.horizontal, 28)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("SCRAMBLE")
                                        .foregroundColor(.white)
                                        .font(.system(size: 17, weight: .medium, design: .rounded))
                                    
                                    Capsule()
                                        .fill(Color.white)
                                        .frame(width: 60, height: 2)
                                        .shadow(color: Color(red: 69/256, green: 98/256, blue: 234/256).opacity(0.2), radius: 12, x: 0, y: 3)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            Text("U' F' L2 D R L2 B D' B' D2 R' B2 R' B2 U2 L' U2 R2 F2 B")
                                .foregroundColor(.white)
                                .font(.system(size: 17, weight: .regular, design: .rounded))
                                .padding(.horizontal)
                            
                        }
                        .frame(width: UIScreen.main.bounds.width - 28*2, height: 230)
                    }
                    .frame(height: 110)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(LinearGradient(gradient: Gradient(colors: [Color(red: 109/256, green: 134/256, blue: 247/256), Color(red: 69/256, green: 98/256, blue: 234/256)]), startPoint: .topLeading, endPoint: .bottomTrailing)).opacity(0.4)
                            .frame(height: 235)
                            .padding(.horizontal, 28)
                        
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("AUDIO ANALYSIS")
                                        .foregroundColor(.white)
                                        .font(.system(size: 17, weight: .medium, design: .rounded))
                                    
                                    Capsule()
                                        .fill(Color.white)
                                        .frame(width: 100, height: 2)
                                        .shadow(color: Color(red: 69/256, green: 98/256, blue: 234/256).opacity(0.2), radius: 12, x: 0, y: 3)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            
                            Text("–     Pauses: \n–     Total Pause Time: ")
                                .foregroundColor(.white)
                                .font(.system(size: 17, weight: .regular, design: .rounded))
                                .padding(.horizontal)
                            
                            VStack(spacing: 4) {
                                HStack(alignment: .bottom, spacing: 8) {
                                    ForEach(0..<20, id: \.self) { thing in
                                        Capsule()
                                            .fill(Color.white)
                                            .frame(width: 4, height: 100)
                                    }
                                    
                                }
                                
                                VStack(spacing: 2) {
                                    HStack {
                                        Capsule()
                                            .fill(Color.white)
                                            .frame(height: 3)
                                            .shadow(color: Color(red: 69/256, green: 98/256, blue: 234/256).opacity(0.2), radius: 12, x: 0, y: 3)
                                    }
                                    .padding(.horizontal)
                                    
                                    
                                    HStack(spacing: 2) {
                                        ForEach(0..<5, id: \.self) { thing in
                                            VStack(spacing: 1) {
                                                Capsule()
                                                    .fill(thing % 2 != 1 ? greenColor : Color.red)
                                                    .frame(height: 3)
                                                    .shadow(color: thing % 2 != 1 ? greenColor.opacity(0.2) : Color.red.opacity(0.2), radius: 12, x: 0, y: 3)

                                                Text("\(thing)")
                                                    .foregroundColor(thing % 2 != 1 ? greenColor : Color.red)
                                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            }

                                        }
                                    }
                                    .padding(.horizontal)
                                    
                                    
                                }
                            }
                        }
                        .frame(width: UIScreen.main.bounds.width - 28*2, height: 235)
                    }
                    
                    
                    Spacer()
                }
                .padding(.top, 100)
            }
            
                    
            VStack {
                HStack {
                    if !showResult {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 45, height: 45)
                            
                            Image(systemName: "waveform")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Text("Solve Analyser")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    } else {
                        Text("Your Solve")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 48)
            
            VStack {
                Spacer()
                Button {
//                    manager.start()
//                    withAnimation(.spring()) {
                        showResult = true
//                    }
                } label: {
                    Text("0.000")
                        .font(.system(size: 64, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .offset(y: showResult ? -UIScreen.main.bounds.height/2 + 150 : 0)
                .scaleEffect(showResult ? 0.75 : 1)
                Spacer()
            }
        }
        
    }
}
