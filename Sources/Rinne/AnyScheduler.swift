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
        if let s = scheduler as? AnyScheduler<S.SchedulerTimeType, S.SchedulerOptions> {
            box = s.box.copy()
        } else {
            box = __AnySchedulerBox(scheduler) { action in
                action()
            }
        }
    }

    @inlinable
    public init<S: Scheduler>(_ scheduler: S, worker: @escaping (@escaping () -> Void) -> Void)
    where SchedulerTimeType == S.SchedulerTimeType,
          SchedulerOptions == S.SchedulerOptions {
        if let s = scheduler as? AnyScheduler<S.SchedulerTimeType, S.SchedulerOptions> {
            box = s.box.copy(with: worker)
        } else {
            box = __AnySchedulerBox(scheduler, worker: worker)
        }
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
    func copy(with worker: ((@escaping () -> Void) -> Void)? = nil) -> Self { fatalError() }

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
    let worker: (@escaping () -> Void) -> Void

    @usableFromInline
    init(_ scheduler: S, worker: @escaping (@escaping () -> Void) -> Void) {
        self.scheduler = scheduler
        self.worker = worker
    }

    @usableFromInline
    override func copy(with newWorker: ((@escaping () -> Void) -> Void)? = nil) -> Self {
        Self.init(scheduler, worker: newWorker ?? worker)
    }

    @usableFromInline
    override func schedule(options: SchedulerOptions?,
                           _ action: @escaping () -> Void) {
        scheduler.schedule(options: options) { [worker] in
            worker(action)
        }
    }

    @usableFromInline
    override func schedule(after date: SchedulerTimeType,
                           tolerance: SchedulerTimeType.Stride,
                           options: SchedulerOptions?,
                           _ action: @escaping () -> Void) {
        scheduler.schedule(after: date,
                           tolerance: tolerance,
                           options: options) { [worker] in
            worker(action)
        }
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
                           options: options) { [worker] in
            worker(action)
        }
    }
}
