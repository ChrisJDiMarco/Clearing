import CoreHaptics
import UIKit

/// Thin wrapper so haptics read intentionally at call sites.
enum Haptics {
    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func soft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    static func rigid() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

final class BreathingHapticPulse {
    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?

    func start() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        stop()
        do {
            let engine = try CHHapticEngine()
            engine.playsHapticsOnly = true
            try engine.start()

            let player = try engine.makeAdvancedPlayer(with: Self.pattern())
            player.loopEnabled = true
            player.loopEnd = 8
            try player.start(atTime: CHHapticTimeImmediate)

            self.engine = engine
            self.player = player
        } catch {
            stop()
        }
    }

    func stop() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
        engine?.stop(completionHandler: nil)
        engine = nil
    }

    private static func pattern() throws -> CHHapticPattern {
        let breath = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.06),
            ],
            relativeTime: 0,
            duration: 8
        )
        let intensity = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                .init(relativeTime: 0, value: 0.06),
                .init(relativeTime: 2.4, value: 0.22),
                .init(relativeTime: 4, value: 0.30),
                .init(relativeTime: 6.2, value: 0.14),
                .init(relativeTime: 8, value: 0.05),
            ],
            relativeTime: 0
        )
        let softness = CHHapticParameterCurve(
            parameterID: .hapticSharpnessControl,
            controlPoints: [
                .init(relativeTime: 0, value: 0.04),
                .init(relativeTime: 4, value: 0.12),
                .init(relativeTime: 8, value: 0.04),
            ],
            relativeTime: 0
        )
        return try CHHapticPattern(events: [breath], parameterCurves: [intensity, softness])
    }
}
