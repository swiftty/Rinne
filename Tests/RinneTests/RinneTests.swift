import XCTest
import Rinne

private class MyStore: Store<MyStore> {
    enum Action {
        case setValue(Int)
    }
    struct State {
        var value: Int
    }
    typealias Environment = Void

    func reduce(state: inout State, action: Action, environment: Environment) -> Effect<Action, Never> {
        switch action {
        case .setValue(let value):
            state.value = value
            return nil
        }
    }
}

final class RinneTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        let store = MyStore(initialState: .init(value: 0), environment: ())
        XCTAssertEqual(store.state.value, 0)

        store.action.send(.setValue(10))

        XCTAssertEqual(store.state.value, 10)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
