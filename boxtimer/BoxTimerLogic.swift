import Foundation
import SwiftUI

/// manages all timer logic an state.
class WorkoutTimer: ObservableObject {
    // MARK: – Configurable
    @Published var totalRounds: Int = 3
    @Published var roundTime: Double = 10
    @Published var restTime: Double = 5

    // MARK: – Runtime State
    @Published private(set) var currentRound: Int = 1
    @Published private(set) var isWorking: Bool = false
    @Published private(set) var isResting: Bool = false
    @Published private(set) var timeRemaining: Double = 0
    @Published private(set) var isRunning: Bool = false

    private var timer: Timer?

    /// Duration of the current phase
    var currentDuration: Double {
        isWorking ? roundTime : (isResting ? restTime : 0)
    }

    /// Fraction (0→1) for progress bars
    var progress: Double {
        guard currentDuration > 0 else { return 0 }
        return 1 - (timeRemaining / currentDuration)
    }

    // MARK: – Public Controls

    /// Starts a new session from the beginning.
    func start() {
        guard !isRunning else { return }

        isWorking = true
        isResting = false
        isRunning = true
        timeRemaining = roundTime

        startTimer()
    }

    /// Resumes from a paused state without resetting time or phase.
    func resume() {
        guard !isRunning, timeRemaining > 0 else { return }

        isRunning = true
        startTimer()
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func reset() {
        pause()
        isWorking = false
        isResting = false
        currentRound = 1
        timeRemaining = 0
    }

    // MARK: – Internal Logic

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else if isWorking {
            // Work complete → start rest
            isWorking = false
            isResting = true
            timeRemaining = restTime
        } else if isResting {
            // Rest complete → next round or end
            currentRound += 1
            if currentRound > totalRounds {
                reset()
            } else {
                isWorking = true
                isResting = false
                timeRemaining = roundTime
            }
        }
    }
}
