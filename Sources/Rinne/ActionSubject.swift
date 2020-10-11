import Combine

public final class ActionSubject<Output>: Subject {
    public typealias Output = Output
    public typealias Failure = Never

    private let subject = PassthroughSubject<Output, Failure>()

    public func send(_ value: Output) {
        subject.send(value)
    }

    public func send(completion: Subscribers.Completion<Failure>) {
        // do not call completion
    }

    public func send(subscription: Subscription) {
        subject.send(subscription: subscription)
    }


    public func receive<S>(subscriber: S) where S: Subscriber, S.Input == Output, S.Failure == Failure {
        subject.receive(subscriber: subscriber)
    }
}
