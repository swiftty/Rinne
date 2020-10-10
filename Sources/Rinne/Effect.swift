import Combine

///
///
public struct Effect<Output, Failure: Error>: Publisher {
    public let upstream: AnyPublisher<Output, Failure>

    public func receive<S>(subscriber: S)
    where S : Subscriber, Failure == S.Failure, Output == S.Input {
        upstream.subscribe(subscriber)
    }
}

extension Effect {
    public init<P: Publisher>(_ publisher: P)
    where Output == P.Output, Failure == P.Failure {
        upstream = publisher.eraseToAnyPublisher()
    }

    public init(value: Output) {
        self.init(Just(value).setFailureType(to: Failure.self))
    }

    public init(error: Failure) {
        self.init(Fail(error: error))
    }
}

extension Effect: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .none
    }
}

extension Effect {
    public static var none: Effect {
        Empty(completeImmediately: true)
            .eraseToEffect()
    }
}

///
///
///
extension Publisher {
    public func eraseToEffect() -> Effect<Output, Failure> {
        if let effect = self as? Effect<Output, Failure> {
            return effect
        }
        return Effect(self)
    }
}
