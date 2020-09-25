import Combine

public final class TestScheduler<SchedulerTimeType, SchedulerOptions>: Scheduler
where SchedulerTimeType: Strideable,
      SchedulerTimeType.Stride: SchedulerTimeIntervalConvertible {

    public var now: SchedulerTimeType
    public var minimumTolerance: SchedulerTimeType.Stride = 0

    public init(now: SchedulerTimeType) {
        self.now = now
    }

    public func schedule(options: SchedulerOptions?,
                         _ action: @escaping () -> Void) {
        fatalError()
    }

    public func schedule(after date: SchedulerTimeType,
                         tolerance: SchedulerTimeType.Stride,
                         options: SchedulerOptions?,
                         _ action: @escaping () -> Void) {
        fatalError()
    }

    public func schedule(after date: SchedulerTimeType,
                         interval: SchedulerTimeType.Stride,
                         tolerance: SchedulerTimeType.Stride,
                         options: SchedulerOptions?,
                         _ action: @escaping () -> Void) -> Cancellable {
        fatalError()
    }
}
