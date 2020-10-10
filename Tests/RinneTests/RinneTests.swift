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
        Publishers
            .Merge(
                state
                    .flatMapLatest {
                        Just($0.value)
                            .delay(for: .seconds(10), scheduler: environment.scheduler)
                    }
                    .filter { $0 > 5 }
                    .map { _ in Mutation.setValue(0) },
                state.map(\.value)
                    .filter { $0 > 100 }
                    .map { _ in Mutation.setValue(50) }
            )
            .eraseToEffect()
    }
}

final class RinneTests: XCTestCase {
    func testExample() {
        let env = Environment()
        let store = MyStore(initialState: .init(value: 0), environment: env)
        XCTAssertEqual(store.state.value, 0)

        store.action.send(.setValue(10))

        XCTAssertEqual(store.state.value, 10)

        env.scheduler.consume(until: .seconds(10))

        XCTAssertEqual(store.state.value, 0)

        store.action.send(.setValue(20))

        XCTAssertEqual(store.state.value, 20)

        env.scheduler.consume(until: .seconds(9))

        XCTAssertEqual(store.state.value, 20)

        store.action.send(.setValue(5))

        XCTAssertEqual(store.state.value, 5)

        env.scheduler.consume(until: .seconds(1))

        XCTAssertEqual(store.state.value, 5)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
