import AVFoundation

class SoundPlayer {
    static let shared = SoundPlayer()
    private var player: AVAudioPlayer?
    
    private init() {
        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[SoundPlayer] ❌ Audio session error: \(error.localizedDescription)")
        }
    }
    
    func play(_ soundName: String) {
        // Try subdirectory first
        var url = Bundle.main.url(forResource: soundName, withExtension: "wav", subdirectory: "Sounds")
        
        // If not found, try root
        if url == nil {
            url = Bundle.main.url(forResource: soundName, withExtension: "wav")
        }
        
        guard let audioURL = url else {
            print("[SoundPlayer] ❌ Sound not found: \(soundName).wav")
            print("[SoundPlayer] Searched in: Sounds/ and root")
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: audioURL)
            player?.volume = 1.0
            player?.prepareToPlay()
            player?.play()
            print("[SoundPlayer] ▶️ Playing: \(soundName).wav from \(audioURL.path)")
        } catch {
            print("[SoundPlayer] ❌ Error playing sound: \(error.localizedDescription)")
        }
    }
    
    func playActivate() {
        play("activar")
    }
    
    func playDeactivate() {
        play("desactivar")
    }
    
    func playWelcome() {
        play("Welcome")
    }
}
