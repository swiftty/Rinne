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

    @inlinable
    public var now: SchedulerTimeType { box.now }

    @inlinable
    public var minimumTolerance: SchedulerTimeType.Stride { box.minimumTolerance }

    @inlinable
    public init<S: Scheduler>(_ scheduler: S)
    where SchedulerTimeType == S.SchedulerTimeType,
          SchedulerOptions == S.SchedulerOptions {
        box = __AnySchedulerBox(scheduler)
    }

    @inlinable
    public func schedule(options: SchedulerOptions?,
                         _ action: @escaping () -> Void) {
        box.schedule(options: options, action)
    }

    @inlinable
    public func schedule(after date: SchedulerTimeType,
                         tolerance: SchedulerTimeType.Stride,
                         options: SchedulerOptions?,
                         _ action: @escaping () -> Void) {
        box.schedule(after: date,
                     tolerance: tolerance,
                     options: options,
                     action)
    }

    @inlinable
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
    @usableFromInline
    let box: _AnySchedulerBox<SchedulerTimeType, SchedulerOptions>
}

// MARK: - impl -
@usableFromInline
class _AnySchedulerBox<SchedulerTimeType, SchedulerOptions>: Scheduler
where SchedulerTimeType: Strideable,
      SchedulerTimeType.Stride: SchedulerTimeIntervalConvertible {

    @usableFromInline
    var now: SchedulerTimeType { fatalError() }

    @usableFromInline
    var minimumTolerance: SchedulerTimeType.Stride { fatalError() }

    @usableFromInline
    func schedule(options: SchedulerOptions?,
                  _ action: @escaping () -> Void) {
        fatalError()
    }

    @usableFromInline
    func schedule(after date: SchedulerTimeType,
                  tolerance: SchedulerTimeType.Stride,
                  options: SchedulerOptions?,
                  _ action: @escaping () -> Void) {
        fatalError()
    }

    @usableFromInline
    func schedule(after date: SchedulerTimeType,
                  interval: SchedulerTimeType.Stride,
                  tolerance: SchedulerTimeType.Stride,
                  options: SchedulerOptions?,
                  _ action: @escaping () -> Void) -> Cancellable {
        fatalError()
    }
}

@usableFromInline
final class __AnySchedulerBox<S: Scheduler>: _AnySchedulerBox<S.SchedulerTimeType, S.SchedulerOptions> {
    @usableFromInline
    typealias SchedulerTimeType = S.SchedulerTimeType

    @usableFromInline
    typealias SchedulerOptions = S.SchedulerOptions

    @usableFromInline
    override var now: S.SchedulerTimeType { scheduler.now }

    @usableFromInline
    override var minimumTolerance: S.SchedulerTimeType.Stride { scheduler.minimumTolerance }

    @usableFromInline
    let scheduler: S

    @usableFromInline
    init(_ scheduler: S) {
        self.scheduler = scheduler
    }

    @usableFromInline
    override func schedule(options: SchedulerOptions?,
                           _ action: @escaping () -> Void) {
        scheduler.schedule(options: options, action)
    }

    @usableFromInline
    override func schedule(after date: SchedulerTimeType,
                           tolerance: SchedulerTimeType.Stride,
                           options: SchedulerOptions?,
                           _ action: @escaping () -> Void) {
        scheduler.schedule(after: date,
                           tolerance: tolerance,
                           options: options,
                           action)
    }

    @usableFromInline
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
