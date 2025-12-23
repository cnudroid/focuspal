//
//  TimerAudioService.swift
//  FocusPal
//
//  Created by FocusPal Team
//

import AVFoundation
import UIKit

/// Service for ADHD-friendly audio callouts during timer sessions.
/// Announces time milestones and provides countdown for final seconds.
@MainActor
class TimerAudioService: ObservableObject {

    // MARK: - Properties

    private let synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private var announcedMilestones: Set<Int> = []
    private var announcedSeconds: Set<Int> = []

    /// Whether audio callouts are enabled
    @Published var isEnabled: Bool = true

    // MARK: - Milestone Thresholds (in seconds)

    private let milestones: [Int] = [
        15 * 60,  // 15 minutes
        10 * 60,  // 10 minutes
        5 * 60,   // 5 minutes
        60        // 1 minute
    ]

    // MARK: - Initialization

    init() {
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    // MARK: - Public Methods

    /// Call this on each timer tick to check for announcements
    func checkForAnnouncements(remainingTime: TimeInterval, totalDuration: TimeInterval) {
        guard isEnabled else { return }

        let remainingSeconds = Int(remainingTime)

        // Check milestone announcements (15min, 10min, 5min, 1min)
        for milestone in milestones {
            // Only announce if we have enough total duration and haven't announced yet
            if totalDuration > TimeInterval(milestone) &&
               remainingSeconds <= milestone &&
               remainingSeconds > milestone - 1 &&
               !announcedMilestones.contains(milestone) {
                announceMilestone(seconds: milestone)
                announcedMilestones.insert(milestone)
            }
        }

        // Countdown for last 10 seconds
        if remainingSeconds <= 10 && remainingSeconds > 0 && !announcedSeconds.contains(remainingSeconds) {
            announceCountdown(seconds: remainingSeconds)
            announcedSeconds.insert(remainingSeconds)
        }

        // Timer complete - play bang sound
        if remainingSeconds == 0 && !announcedSeconds.contains(0) {
            playCompletionSound()
            announcedSeconds.insert(0)
        }
    }

    /// Reset all announcement tracking (call when timer starts)
    func reset() {
        announcedMilestones.removeAll()
        announcedSeconds.removeAll()
        synthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: - Private Methods

    private func announceMilestone(seconds: Int) {
        let message: String
        switch seconds {
        case 15 * 60:
            message = "Last 15 minutes"
        case 10 * 60:
            message = "Last 10 minutes"
        case 5 * 60:
            message = "Last 5 minutes"
        case 60:
            message = "Last minute"
        default:
            return
        }
        speak(message)
    }

    private func announceCountdown(seconds: Int) {
        speak("\(seconds)")
    }

    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.1
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        // Use a clear voice
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }

        synthesizer.speak(utterance)
    }

    private func playCompletionSound() {
        // First announce "Time's up!"
        let utterance = AVSpeechUtterance(string: "Time's up!")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.2
        utterance.volume = 1.0

        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }

        synthesizer.speak(utterance)

        // Play system sound after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Play a celebratory system sound
            AudioServicesPlaySystemSound(1025) // Fanfare-like sound

            // Also trigger haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // Play additional alert sound
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }
}
