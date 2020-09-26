import XCTest
import Combine
@testable import RinneTest

final class TestSubscriberTests: XCTestCase {
    func testSubscribeWithFinished() {
        let scheduler = DispatchQueue.testScheduler

        let result = scheduler.createSubscriber(input: Int.self, failure: Never.self)

        Record(output: [1, 2, 3, 4], completion: .finished)
            .receive(on: scheduler)
            .receive(subscriber: result)

        XCTAssertEqual(result.events, [])

        scheduler.consume()

        XCTAssertEqual(result.events, [
            .next(1, at: 0),
            .next(2, at: 0),
            .next(3, at: 0),
            .next(4, at: 0),
            .finished(at: 0)
        ])
    }

    func testSubscribeWithFailure() {
        struct Failure: Error, Equatable {}

        let scheduler = DispatchQueue.testScheduler

        let result = scheduler.createSubscriber(input: Int.self, failure: Failure.self)

        Record(output: [1, 2, 3, 4], completion: .failure(Failure()))
            .receive(on: scheduler)
            .receive(subscriber: result)

        XCTAssertEqual(result.events, [])

        scheduler.consume()

        XCTAssertEqual(result.events, [
            .next(1, at: 0),
            .next(2, at: 0),
            .next(3, at: 0),
            .next(4, at: 0),
            .failure(Failure(), at: 0)
        ])
    }
}
