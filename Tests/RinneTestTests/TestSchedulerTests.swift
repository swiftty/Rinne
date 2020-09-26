import XCTest
import Combine
@testable import RinneTest

final class RinneTestTests: XCTestCase {
    var cancellables: Set<AnyCancellable> = []

    func testConsumeByStep() {
        let scheduler = TestSchedulerOf<DispatchQueue>(now: .init(.now()))

        var value: Int?
        Just(1)
            .delay(for: .milliseconds(300), scheduler: scheduler)
            .sink { value = $0 }
            .store(in: &cancellables)

        XCTAssertEqual(value, nil)

        scheduler.consume(until: .milliseconds(100))

        XCTAssertEqual(value, nil)

        scheduler.consume(until: .milliseconds(100))

        XCTAssertEqual(value, nil)

        scheduler.consume(until: .milliseconds(100))

        XCTAssertEqual(value, 1)
    }

    func testConsume() {
        let scheduler = TestSchedulerOf<DispatchQueue>(now: .init(.now()))

        var value: Int?
        Just(1)
            .delay(for: .milliseconds(300), scheduler: scheduler)
            .sink { value = $0 }
            .store(in: &cancellables)

        XCTAssertEqual(value, nil)

        scheduler.consume(until: .milliseconds(100))

        XCTAssertEqual(value, nil)

        scheduler.consume()

        XCTAssertEqual(value, 1)
    }

    func testIntervalOrdering() {
        let scheduler = TestSchedulerOf<DispatchQueue>(now: .init(.now()))

        var values: [Int] = []
        var localCancellables: Set<AnyCancellable> = []

        scheduler.schedule(after: scheduler.now, interval: .seconds(2)) {
            values.append(1)
        }.store(in: &cancellables)

        scheduler.schedule(after: scheduler.now, interval: .seconds(1)) {
            values.append(42)
        }.store(in: &localCancellables)

        XCTAssertEqual(values, [])
        scheduler.consume(until: .zero)
        XCTAssertEqual(values, [1, 42])
        scheduler.consume(until: .seconds(1))
        XCTAssertEqual(values, [1, 42, 42])
        scheduler.consume(until: .seconds(1))
        XCTAssertEqual(values, [1, 42, 42, 1, 42])
        scheduler.consume(until: .seconds(1))
        XCTAssertEqual(values, [1, 42, 42, 1, 42, 42])

        localCancellables = []

        scheduler.consume(until: .seconds(1))
        XCTAssertEqual(values, [1, 42, 42, 1, 42, 42, 1])
    }
}
