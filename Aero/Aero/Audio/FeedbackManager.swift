import SwiftUI
import AVFoundation

class FeedbackManager {
    static let shared = FeedbackManager()
    private var player: AVAudioPlayer?
    
    // MARK: - Standard Interaction
    func triggerClack() {
        guard UserDefaults.standard.bool(forKey: "clackSoundsEnabled") else {
            triggerHaptic()
            return
        }
        
        triggerHaptic()
        playSound(named: "clack")
    }
    
    // MARK: - Warning / System Alert Interaction
    /// Used for the Expired Sweep button to provide a distinct, heavier feedback.
    func triggerWarning() {
        // 1. Notification Haptic (Double pulse)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
        
        // 2. Sound Feedback
        if UserDefaults.standard.bool(forKey: "clackSoundsEnabled") {
            playSound(named: "clack")
        }
    }
    
    // MARK: - Core Haptics
    func triggerHaptic() {
        let intensity = UserDefaults.standard.string(forKey: "hapticIntensity") ?? "Medium"
        
        let style: UIImpactFeedbackGenerator.FeedbackStyle
        switch intensity {
        case "Light":
            style = .light
        case "Heavy":
            style = .heavy
        default:
            style = .medium
        }
        
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // MARK: - Private Sound Engine
    private func playSound(named resourceName: String) {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "wav") else { return }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("FeedbackManager: Could not play sound \(resourceName)")
        }
    }
}
