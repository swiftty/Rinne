import XCTest
import Combine
import Rinne
import RinneTest

extension Publisher {
    func flatMapLatest<T: Publisher>(_ transform: @escaping (Output) -> T)
    -> Publishers.SwitchToLatest<T, Publishers.Map<Self, T>>
    where T.Failure == Failure {
        map(transform).switchToLatest()
    }
}

struct Environment {
    let scheduler = DispatchQueue.testScheduler
}

private class MyStore: Store<MyStore> {
    enum Action {
        case setValue(Int)
    }
    struct State {
        var value: Int
    }
    typealias Mutation = Action

    func mutate(action: Action, environment: Environment) -> Effect<Mutation, Never> {
        .just(action)
    }

    func reduce(state: inout State, mutation: Action, environment: Environment) {
        switch mutation {
        case .setValue(let value):
            state.value = value
        }
    }

    func poll(state: Published<State>.Publisher, environment: Environment) -> Effect<Mutation, Never> {
        Effect.merge(
            state
                .flatMapLatest {
                    Just($0.value)
                        .delay(for: .seconds(10), scheduler: environment.scheduler)
                }
                .filter { $0 > 5 }
                .map { _ in Mutation.setValue(0) },
            state
                .flatMapLatest {
                    Just($0.value)
                        .delay(for: .seconds(5), scheduler: environment.scheduler)
                }
                .filter { $0 > 100 }
                .map { _ in Mutation.setValue(1) }
        )
    }
}

final class StoreTests: XCTestCase {
    func testStateFlow() {
        let env = Environment()
        let store = MyStore(initialState: .init(value: 0), environment: env)

        let values = env.scheduler.createSubscriber(input: Int.self, failure: Never.self)
        store.$state
            .map(\.value)
            .receive(subscriber: values)

        store.action.send(.setValue(10))
        env.scheduler.consume(until: .seconds(10))
        store.action.send(.setValue(20))
        env.scheduler.consume(until: .seconds(9))
        store.action.send(.setValue(5))
        env.scheduler.consume(until: .seconds(1))
        store.action.send(.setValue(200))
        env.scheduler.consume(until: .seconds(5))

        env.scheduler.consume()

        XCTAssertEqual(values.events, [
            .next(0, at: .seconds(0)),
            .next(10, at: .seconds(0)),
            .next(0, at: .seconds(10)),
            .next(20, at: .seconds(10)),
            .next(5, at: .seconds(19)),
            .next(200, at: .seconds(20)),
            .next(1, at: .seconds(25))
        ])
    }

    static var allTests = [
        ("testStateFlow", testStateFlow),
    ]
}
