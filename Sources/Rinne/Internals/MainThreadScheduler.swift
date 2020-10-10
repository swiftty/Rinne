import Combine
import Dispatch

private struct SpecificValue: Hashable {}
private let key = DispatchSpecificKey<SpecificValue>()
private let value = SpecificValue()
private let scheduler = DispatchQueue.main

struct MainThreadScheduler: Scheduler {
    typealias SchedulerOptions = DispatchQueue.SchedulerOptions
    typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType

    var now: SchedulerTimeType { scheduler.now }
    var minimumTolerance: SchedulerTimeType.Stride { scheduler.minimumTolerance }

    private static let shared = MainThreadScheduler {
        scheduler.setSpecific(key: key, value: value)
    }

    init() {
        self = Self.shared
    }

    private init(initializer: () -> Void) {
        initializer()
    }

    func schedule(options: DispatchQueue.SchedulerOptions?, _ action: @escaping () -> Void) {
        if DispatchQueue.getSpecific(key: key) == value {
            action()
        } else {
            scheduler.schedule(options: options, action)
        }
    }

    func schedule(after date: DispatchQueue.SchedulerTimeType,
                  tolerance: DispatchQueue.SchedulerTimeType.Stride,
                  options: DispatchQueue.SchedulerOptions?,
                  _ action: @escaping () -> Void) {
        scheduler.schedule(after: date, tolerance: tolerance, options: options, action)
    }

    func schedule(after date: DispatchQueue.SchedulerTimeType,
                  interval: DispatchQueue.SchedulerTimeType.Stride,
                  tolerance: DispatchQueue.SchedulerTimeType.Stride,
                  options: DispatchQueue.SchedulerOptions?,
                  _ action: @escaping () -> Void) -> Cancellable {
        scheduler.schedule(after: date, interval: interval, tolerance: tolerance, options: options, action)
    }
}
