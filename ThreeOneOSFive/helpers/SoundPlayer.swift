import AVFoundation
import UIKit

class SoundPlayer {
    static let shared = SoundPlayer()
    private var player: AVAudioPlayer?
    
    private init() {
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            print("[SoundPlayer] ✅ Audio session configured")
        } catch {
            print("[SoundPlayer] ❌ Audio session error: \(error)")
        }
    }
    
    func play(_ soundName: String) {
        DispatchQueue.main.async { [weak self] in
            self?.playOnMainThread(soundName)
        }
    }
    
    private func playOnMainThread(_ soundName: String) {
        // Try different paths
        let possiblePaths = [
            Bundle.main.path(forResource: soundName, ofType: "wav", inDirectory: "Sounds"),
            Bundle.main.path(forResource: soundName, ofType: "wav", inDirectory: "ThreeOneOSFive/Sounds"),
            Bundle.main.path(forResource: soundName, ofType: "wav"),
            Bundle.main.path(forResource: "Sounds/\(soundName)", ofType: "wav")
        ]
        
        guard let path = possiblePaths.compactMap({ $0 }).first else {
            print("[SoundPlayer] ❌ Sound not found: \(soundName).wav")
            print("[SoundPlayer] Searched paths:")
            possiblePaths.forEach { path in
                print("  - \(path ?? "nil")")
            }
            
            // List all bundle resources
            if let resourcePath = Bundle.main.resourcePath {
                print("[SoundPlayer] Bundle resources:")
                if let contents = try? FileManager.default.contentsOfDirectory(atPath: resourcePath) {
                    contents.filter { $0.hasSuffix(".wav") }.forEach { file in
                        print("  - \(file)")
                    }
                }
            }
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            // Stop previous sound
            player?.stop()
            
            // Create new player
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = 1.0
            player?.numberOfLoops = 0
            
            // Prepare and play
            if player?.prepareToPlay() == true {
                if player?.play() == true {
                    print("[SoundPlayer] ▶️ Playing: \(soundName).wav from \(path)")
                } else {
                    print("[SoundPlayer] ❌ Failed to start playback")
                }
            } else {
                print("[SoundPlayer] ❌ Failed to prepare")
            }
        } catch {
            print("[SoundPlayer] ❌ Error: \(error.localizedDescription)")
        }
    }
    
    func playActivate() {
        print("[SoundPlayer] 🎵 Request: activar")
        play("activar")
        // Also trigger haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func playDeactivate() {
        print("[SoundPlayer] 🎵 Request: desactivar")
        play("desactivar")
        // Also trigger haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func playWelcome() {
        print("[SoundPlayer] 🎵 Request: Welcome")
        play("Welcome")
    }
}
