import XCTest
import Combine
@testable import RinneTest

final class TestSubscriberTests: XCTestCase {
    func testSubscribeAndFinished() {
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

    func testSubscribeAndFailure() {
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

    func testSubscribeWithTime() {
        let scheduler = DispatchQueue.testScheduler

        let result = scheduler.createSubscriber(input: Int.self, failure: Never.self)

        Publishers
            .MergeMany(
                Just(1)
                    .delay(for: .seconds(1), scheduler: scheduler),
                Just(2)
                    .delay(for: .seconds(2), scheduler: scheduler),
                Just(3)
                    .delay(for: .seconds(3), scheduler: scheduler),
                Just(4)
                    .delay(for: .seconds(4), scheduler: scheduler))
            .receive(subscriber: result)

        XCTAssertEqual(result.events, [])

        scheduler.consume(until: .seconds(1))

        XCTAssertEqual(result.events, [
            .next(1, at: .seconds(1))
        ])

        scheduler.consume(until: .seconds(2))

        XCTAssertEqual(result.events, [
            .next(1, at: .seconds(1)),
            .next(2, at: .seconds(2)),
            .next(3, at: .seconds(3))
        ])

        scheduler.consume(until: .seconds(1))

        XCTAssertEqual(result.events, [
            .next(1, at: .seconds(1)),
            .next(2, at: .seconds(2)),
            .next(3, at: .seconds(3)),
            .next(4, at: .seconds(4)),
            .finished(at: .seconds(4))
        ])
    }
}
