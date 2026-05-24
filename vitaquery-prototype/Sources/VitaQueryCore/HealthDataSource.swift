import Foundation

/// Abstraction over HealthKit so we can plug stubs into tests. The real
/// implementation lives in `VitaQueryPhone/HealthKitDataSource.swift` and
/// uses `HKStatisticsCollectionQuery`.
public protocol HealthDataSource: Sendable {
    func summary(windowDays: Int) async throws -> HealthSummary
}

public struct EmptyHealthDataSource: HealthDataSource {
    public init() {}
    public func summary(windowDays: Int) async throws -> HealthSummary {
        HealthSummary(windowDays: windowDays)
    }
}
