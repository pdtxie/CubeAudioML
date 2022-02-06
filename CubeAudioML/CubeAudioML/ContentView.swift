import SwiftUI
import AVFoundation
import SoundAnalysis

class Manager: NSObject, SNResultsObserving, ObservableObject {
    func request(_ request: SNRequest, didProduce result: SNResult) {
        NSLog("i have no idae what is going on: \(result)")
    }
    
    private let audioEngine = AVAudioEngine()
    private var soundClassifier = CubeSoundClassifier()
    var streamAnalyzer: SNAudioStreamAnalyzer!
    
    private func startAudio() {
        audioEngine.prepare()
        try! audioEngine.start()
    }
    
    private func prepare() {
        let inputNode = audioEngine.inputNode
        let recFmt = inputNode.outputFormat(forBus: 0)
        streamAnalyzer = SNAudioStreamAnalyzer(format: recFmt)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recFmt) {
            [unowned self] (buffer, when) in
            DispatchQueue.global(qos: .userInitiated).async {
                self.streamAnalyzer.analyze(buffer, atAudioFramePosition: when.sampleTime)
                NSLog("i think it is analyzing something")
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
