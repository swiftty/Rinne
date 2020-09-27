import Combine

///
///
///
public typealias AnySchedulerOf<Scheduler> = AnyScheduler<
    Scheduler.SchedulerTimeType,
    Scheduler.SchedulerOptions
> where Scheduler: Combine.Scheduler

///
///
///
public final class AnyScheduler<SchedulerTimeType, SchedulerOptions>: Scheduler
where SchedulerTimeType: Strideable,
      SchedulerTimeType.Stride: SchedulerTimeIntervalConvertible {

    public var now: SchedulerTimeType { box.now }
    public var minimumTolerance: SchedulerTimeType.Stride { box.minimumTolerance }

    public init<S: Scheduler>(_ scheduler: S)
    where SchedulerTimeType == S.SchedulerTimeType,
          SchedulerOptions == S.SchedulerOptions {
        box = AnySchedulerBox(scheduler)
    }

    public func schedule(options: SchedulerOptions?,
                         _ action: @escaping () -> Void) {
        box.schedule(options: options, action)
    }

    public func schedule(after date: SchedulerTimeType,
                         tolerance: SchedulerTimeType.Stride,
                         options: SchedulerOptions?,
                         _ action: @escaping () -> Void) {
        box.schedule(after: date,
                     tolerance: tolerance,
                     options: options,
                     action)
    }

    public func schedule(after date: SchedulerTimeType,
                         interval: SchedulerTimeType.Stride,
                         tolerance: SchedulerTimeType.Stride,
                         options: SchedulerOptions?,
                         _ action: @escaping () -> Void) -> Cancellable {
        box.schedule(after: date,
                     interval: interval,
                     tolerance: tolerance,
                     options: options,
                     action)
    }

    // MARK:
    private let box: _AnySchedulerBox<SchedulerTimeType, SchedulerOptions>
}

// MARK: - private
private class _AnySchedulerBox<SchedulerTimeType, SchedulerOptions>: Scheduler
where SchedulerTimeType: Strideable,
      SchedulerTimeType.Stride: SchedulerTimeIntervalConvertible {

    var now: SchedulerTimeType { fatalError() }
    var minimumTolerance: SchedulerTimeType.Stride { fatalError() }

    func schedule(options: SchedulerOptions?,
                  _ action: @escaping () -> Void) {
        fatalError()
    }

    func schedule(after date: SchedulerTimeType,
                  tolerance: SchedulerTimeType.Stride,
                  options: SchedulerOptions?,
                  _ action: @escaping () -> Void) {
        fatalError()
    }

    func schedule(after date: SchedulerTimeType,
                  interval: SchedulerTimeType.Stride,
                  tolerance: SchedulerTimeType.Stride,
                  options: SchedulerOptions?,
                  _ action: @escaping () -> Void) -> Cancellable {
        fatalError()
    }
}

private final class AnySchedulerBox<S: Scheduler>: _AnySchedulerBox<S.SchedulerTimeType, S.SchedulerOptions> {
    typealias SchedulerTimeType = S.SchedulerTimeType
    typealias SchedulerOptions = S.SchedulerOptions

    override var now: S.SchedulerTimeType { scheduler.now }
    override var minimumTolerance: S.SchedulerTimeType.Stride { scheduler.minimumTolerance }

    let scheduler: S

    init(_ scheduler: S) {
        self.scheduler = scheduler
    }

    override func schedule(options: SchedulerOptions?,
                           _ action: @escaping () -> Void) {
        scheduler.schedule(options: options, action)
    }

    override func schedule(after date: SchedulerTimeType,
                           tolerance: SchedulerTimeType.Stride,
                           options: SchedulerOptions?,
                           _ action: @escaping () -> Void) {
        scheduler.schedule(after: date,
                           tolerance: tolerance,
                           options: options,
                           action)
    }

    override func schedule(after date: SchedulerTimeType,
                           interval: SchedulerTimeType.Stride,
                           tolerance: SchedulerTimeType.Stride,
                           options: SchedulerOptions?,
                           _ action: @escaping () -> Void) -> Cancellable {
        scheduler.schedule(after: date,
                           interval: interval,
                           tolerance: tolerance,
                           options: options,
                           action)
    }
}
