#if canImport(XCTest)

import XCTest
import Combine

extension Scheduler
where SchedulerTimeType == DispatchQueue.SchedulerTimeType,
      SchedulerOptions == DispatchQueue.SchedulerOptions {
    public static var testScheduler: TestSchedulerOf<Self> { .init(now: .init(.now())) }
}

extension Scheduler
where SchedulerTimeType == RunLoop.SchedulerTimeType,
      SchedulerOptions == RunLoop.SchedulerOptions {
    public static var testScheduler: TestSchedulerOf<Self> { .init(now: .init(.init(timeIntervalSince1970: 0))) }
}

extension Scheduler
where SchedulerTimeType == OperationQueue.SchedulerTimeType,
      SchedulerOptions == OperationQueue.SchedulerOptions {
    public static var testScheduler: TestSchedulerOf<Self> { .init(now: .init(.init(timeIntervalSince1970: 0))) }
}

#endif
