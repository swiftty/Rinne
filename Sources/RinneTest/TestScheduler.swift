import Combine

public final class TestScheduler<SchedulerTimeType, SchedulerOptions>: Scheduler
where SchedulerTimeType: Strideable,
      SchedulerTimeType.Stride: SchedulerTimeIntervalConvertible {

    private typealias Tick = UInt64

    public private(set) var now: SchedulerTimeType
    public let minimumTolerance: SchedulerTimeType.Stride = 0

    private var lastTick = 0 as Tick
    private var queue: [(tick: Tick, date: SchedulerTimeType, action: () -> Void)] = []

    public init(now: SchedulerTimeType) {
        self.now = now
    }

    public func schedule(options: SchedulerOptions?,
                         _ action: @escaping () -> Void) {
        enqueue(tick: nextTick(), date: now, action: action)
    }

    public func schedule(after date: SchedulerTimeType,
                         tolerance: SchedulerTimeType.Stride,
                         options: SchedulerOptions?,
                         _ action: @escaping () -> Void) {
        enqueue(tick: nextTick(), date: date, action: action)
    }

    public func schedule(after date: SchedulerTimeType,
                         interval: SchedulerTimeType.Stride,
                         tolerance: SchedulerTimeType.Stride,
                         options: SchedulerOptions?,
                         _ action: @escaping () -> Void) -> Cancellable {
        let tick = nextTick()

        var scheduleAction: ((SchedulerTimeType) -> () -> Void)!
        scheduleAction = { [weak self] date in
            return {
                let next = date.advanced(by: interval)
                self?.enqueue(tick: tick, date: next, action: scheduleAction(next))
                action()
            }
        }

        enqueue(tick: tick, date: date, action: scheduleAction(date))

        return AnyCancellable { [weak self] in
            self?.dequeue(for: tick)
        }
    }

    private func enqueue(tick: Tick, date: SchedulerTimeType, action: @escaping () -> Void) {

    }

    private func dequeue(for tick: Tick) {
        queue.removeAll(where: { $0.tick == tick })
    }

    private func nextTick() -> Tick {
        lastTick += 1
        return lastTick
    }
}

extension TestScheduler {
    public func consume() {
        while let date = queue.first?.date {
            consume(until: date)
        }
    }

    public func consume(until end: SchedulerTimeType) {
        while now <= end {
            queue.sort(by: { ($0.date, $0.tick) < ($1.date, $1.tick) })

            guard let next = queue.first?.date, end >= next else {
                now = end
                return
            }

            now = next

            while let (_, date, action) = queue.first, date == next {
                queue.removeFirst()
                action()
            }
        }
    }
}
