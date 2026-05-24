import Foundation

/// The privacy-minimal aggregation that the LLM sees. Never includes raw
/// samples — only statistics derived from them.
public struct HealthSummary: Codable, Sendable {
    public let generatedAt: Date
    public let windowDays: Int
    public let resting: VitalStat?
    public let hrv: VitalStat?
    public let sleep: SleepStat?
    public let workout: WorkoutStat?

    public init(
        generatedAt: Date = Date(),
        windowDays: Int = 7,
        resting: VitalStat? = nil,
        hrv: VitalStat? = nil,
        sleep: SleepStat? = nil,
        workout: WorkoutStat? = nil
    ) {
        self.generatedAt = generatedAt
        self.windowDays = windowDays
        self.resting = resting
        self.hrv = hrv
        self.sleep = sleep
        self.workout = workout
    }
}

public struct VitalStat: Codable, Sendable {
    public let mean: Double
    public let stddev: Double
    /// Week-over-week change as a fraction (e.g. -0.08 = 8% lower than prior week).
    public let weekDelta: Double
    /// Percentile of the latest reading vs. the rolling 30-day distribution.
    public let latestPercentile: Double

    public init(mean: Double, stddev: Double, weekDelta: Double, latestPercentile: Double) {
        self.mean = mean
        self.stddev = stddev
        self.weekDelta = weekDelta
        self.latestPercentile = latestPercentile
    }
}

public struct SleepStat: Codable, Sendable {
    public let averageHoursPerNight: Double
    public let stddevHours: Double
    public let weekDelta: Double
    /// Number of nights in window where the user slept < 6.5h.
    public let shortNights: Int

    public init(averageHoursPerNight: Double, stddevHours: Double, weekDelta: Double, shortNights: Int) {
        self.averageHoursPerNight = averageHoursPerNight
        self.stddevHours = stddevHours
        self.weekDelta = weekDelta
        self.shortNights = shortNights
    }
}

public struct WorkoutStat: Codable, Sendable {
    public let sessionsInWindow: Int
    public let totalMinutes: Int
    public let weekDeltaSessions: Int
    public let avgIntensity: Double   // 0..1, derived from kcal/min

    public init(sessionsInWindow: Int, totalMinutes: Int, weekDeltaSessions: Int, avgIntensity: Double) {
        self.sessionsInWindow = sessionsInWindow
        self.totalMinutes = totalMinutes
        self.weekDeltaSessions = weekDeltaSessions
        self.avgIntensity = avgIntensity
    }
}
