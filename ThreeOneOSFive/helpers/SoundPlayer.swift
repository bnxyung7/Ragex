import AVFoundation

class SoundPlayer {
    static let shared = SoundPlayer()
    private var player: AVAudioPlayer?
    
    private init() {}
    
    func play(_ soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "wav", subdirectory: "Sounds") else {
            print("[SoundPlayer] ❌ Sound not found: \(soundName).wav")
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
            print("[SoundPlayer] ▶️ Playing: \(soundName).wav")
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
