import XCTest
import Combine
@testable import RinneTest

final class TestSubscriberTests: XCTestCase {
    func testSubscribeWithFinished() {
        let scheduler = DispatchQueue.testScheduler

        let result = TestSubscriber<Int, Never>()

        Record(output: [1, 2, 3, 4], completion: .finished)
            .receive(on: scheduler)
            .receive(subscriber: result)

        XCTAssertEqual(result.events, [])

        scheduler.consume()

        XCTAssertEqual(result.events, [
            .next(1),
            .next(2),
            .next(3),
            .next(4),
            .finished
        ])
    }

    func testSubscribeWithFailure() {
        struct Failure: Error, Equatable {}

        let scheduler = DispatchQueue.testScheduler

        let result = TestSubscriber<Int, Failure>()

        Record(output: [1, 2, 3, 4], completion: .failure(Failure()))
            .receive(on: scheduler)
            .receive(subscriber: result)

        XCTAssertEqual(result.events, [])

        scheduler.consume()

        XCTAssertEqual(result.events, [
            .next(1),
            .next(2),
            .next(3),
            .next(4),
            .failure(Failure())
        ])
    }
}
