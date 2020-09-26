import Combine

public final class TestSubscriber<Input, Failure: Error>: Subscriber, Cancellable {
    public enum Event {
        case next(Input)
        case finished
        case failure(Failure)
    }

    public private(set) var events: [Event] = []

    private var subscription: Subscription?

    public func receive(subscription: Subscription) {
        self.subscription = subscription
        subscription.request(.unlimited)
    }

    public func receive(_ input: Input) -> Subscribers.Demand {
        events.append(.next(input))
        return .none
    }

    public func receive(completion: Subscribers.Completion<Failure>) {
        switch completion {
        case .finished:
            events.append(.finished)

        case .failure(let error):
            events.append(.failure(error))
        }
        cancel()
    }

    public func cancel() {
        subscription?.cancel()
        subscription = nil
    }
}

extension TestSubscriber.Event: Equatable where Input: Equatable, Failure: Equatable {}
