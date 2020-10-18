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
    enum Event {
        case over10(value: Int)
        case reset0
    }
    typealias Mutation = Action

    init(environment: Environment) {
        super.init(initialState: .init(value: 0), environment: environment)
    }

    func mutate(action: Action, environment: Environment) -> Effect<Mutation, Never> {
        .just(action)
    }

    func reduce(state: inout State, mutation: Action) -> Effect<Event, Never> {
        switch mutation {
        case .setValue(let value):
            state.value = value
        }
        if state.value > 10 {
            return .just(.over10(value: state.value))
        }
        if state.value == 0 {
            return .just(.reset0)
        }
        return nil
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
        let store = MyStore(environment: env)

        let values = env.scheduler.createSubscriber(input: Int.self, failure: Never.self)
        store.$state.value
            .receive(subscriber: values)

        store.action.send(completion: .finished)

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

    func testStateUsingScenario() {
        let env = Environment()

        let scenario = TestScenario(MyStore(environment: env))
        scenario(
            .then {
                $0.value = 0
            },
            .action(.setValue(10)) {
                $0.value = 10
            },
            .do(env.scheduler.consume(until: .seconds(10))) {
                $0.value = 0
            },
            .receive(event: .reset0),
            .action(.setValue(20)) {
                $0.value = 20
            },
            .receive(event: .over10(value: 20)),
            .do(env.scheduler.consume(until: .seconds(9))),
            .action(.setValue(5)) {
                $0.value = 5
            },
            .do(env.scheduler.consume(until: .seconds(1))),
            .action(.setValue(200)) {
                $0.value = 200
            },
            .receive(event: .over10(value: 200)),
            .do(env.scheduler.consume(until: .seconds(5))) {
                $0.value = 1
            },
            .action(.setValue(30)) {
                $0.value = 30
            },
            .receive(event: .over10(value: 30))
        )
    }

    static var allTests = [
        ("testStateFlow", testStateFlow),
    ]
}
