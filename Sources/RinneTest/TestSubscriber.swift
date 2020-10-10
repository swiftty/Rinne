import Combine

public final class TestSubscriber<Input, Failure: Error, Stride>: Subscriber, Cancellable {
    public struct Record {
        public let time: Stride
        public let value: Event
    }

    public enum Event {
        case next(Input)
        case finished
        case failure(Failure)
    }

    public private(set) var events = Array<Record>()

    private var appendEvent: (Event) -> Void = { _ in }
    private var subscription: Subscription?

    init<SchedulerTime, SchedulerOptions>(scheduler: TestScheduler<SchedulerTime, SchedulerOptions>)
    where SchedulerTime.Stride == Stride {
        let start = scheduler.now
        appendEvent = { [weak self, weak scheduler] event in
            guard let scheduler = scheduler else { return }
            self?.events.append(.init(time: start.distance(to: scheduler.now), value: event))
        }
    }

    public func receive(subscription: Subscription) {
        self.subscription = subscription
        subscription.request(.unlimited)
    }

    public func receive(_ input: Input) -> Subscribers.Demand {
        appendEvent(.next(input))
        return .none
    }

    public func receive(completion: Subscribers.Completion<Failure>) {
        switch completion {
        case .finished:
            appendEvent(.finished)

        case .failure(let error):
            appendEvent(.failure(error))
        }
        cancel()
    }

    public func cancel() {
        subscription?.cancel()
        subscription = nil
    }
}

extension TestSubscriber {
    public struct Array<Element>: RandomAccessCollection, ExpressibleByArrayLiteral {
        public var startIndex: Int { raw.startIndex }
        public var endIndex: Int { raw.endIndex }

        public subscript(position: Int) -> Element {
            get { raw[position] }
            set { raw[position] = newValue }
        }

        public init(arrayLiteral elements: Element...) {
            raw = elements
        }

        public func index(after i: Int) -> Int { raw.index(after: i) }

        public mutating func append(_ newElement: Element) { raw.append(newElement) }


        private var raw: [Element] = []
    }
}

extension TestSubscriber.Array: Equatable where Element: Equatable {}
extension TestSubscriber.Array: Hashable where Element: Hashable {}

extension TestSubscriber.Array: CustomDebugStringConvertible where Element == TestSubscriber.Record {
    public var debugDescription: String {
        var str = ""
        str += "\n"
        for e in dropLast() {
            str += """
              ┣ \(e.value)
              ┃    ┗ @ \(e.time),\n
            """
        }
        if let last = last {
            str += """
              ┗ \(last.value)
                     ┗ @ \(last.time)\n
            """
        }
        return str
    }
}

// MARK: - Record
extension TestSubscriber.Record: Equatable where Input: Equatable, Failure: Equatable, Stride: Equatable {
    public static func next(_ input: Input, at time: Stride) -> Self {
        self.init(time: time, value: .next(input))
    }

    public static func finished(at time: Stride) -> Self {
        self.init(time: time, value: .finished)
    }

    public static func failure(_ error: Failure, at time: Stride) -> Self {
        self.init(time: time, value: .failure(error))
    }
}

// MARK: - Event
extension TestSubscriber.Event: Equatable where Input: Equatable, Failure: Equatable, Stride: Equatable {}

extension TestSubscriber.Event: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .next(let next): return ".next(\(next))"
        case .finished: return ".finished"
        case .failure(let error): return ".failure(\(error))"
        }
    }
}
