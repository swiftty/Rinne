#if canImport(XCTest)

import XCTest
import Combine
import Rinne

public final class TestScenario<Store: _StoreType> {
    private let store: () -> Store

    public init(_ store: @autoclosure @escaping () -> Store) {
        self.store = store
    }

    public func callAsFunction(_ steps: Step...,
                               file: StaticString = #filePath, line: UInt = #line) {
        callAsFunction(steps, file: file, line: line)
    }

    public func callAsFunction(_ steps: [Step],
                               file: StaticString = #filePath, line: UInt = #line) {
        let store = self.store()
        var cancellables: Set<AnyCancellable> = []
        var receivedEvents: [Store.Event] = []
        var expectedState = store.state

        store.events
            .sink(receiveValue: {
                receivedEvents.append($0)
            })
            .store(in: &cancellables)

        func checkReceivedEvent(in step: Step? = nil) {
            if !receivedEvents.isEmpty {
                XCTFail("""
                Must handle \(receivedEvents.count) received \
                event\(receivedEvents.count == 1 ? "" : "s") \
                \(step == nil ? "remaining in scenario" : "before performing this step").

                Unhandled events: \(debugOutput(receivedEvents))
                """, file: step?.file ?? file, line: step?.line ?? line)
            }
        }
        defer {
            checkReceivedEvent()
        }

        for step in steps {
            var checkState = true

            do {
                switch step.kind {
                case .action(let action, let update):
                    checkReceivedEvent(in: step)
                    store.action.send(action)
                    try update(&expectedState)

                case .do(let work, let then):
                    checkReceivedEvent(in: step)
                    try work()
                    try then(&expectedState)

                case .then(let update):
                    checkReceivedEvent(in: step)
                    try update(&expectedState)

                case .receive(let event):
                    checkState = false
                    guard !receivedEvents.isEmpty else {
                        XCTFail("""
                        Expected to receive an event, but received none.
                        """, file: step.file, line: step.line)
                        break
                    }
                    let receivedEvent = receivedEvents.removeFirst()
                    if case let expected = debugOutput(event),
                       case let actual = debugOutput(receivedEvent),
                       expected != actual {
                        let diff = RinneTest.diff(expected, actual)
                            .map {
                                """
                                \($0.indent(by: 4))

                                  ----
                                  (Expected: -, Actual: +)
                                """
                            } ?? """
                            Expected:
                            \(expected.indent(by: 2))

                            Actual:
                            \(actual.indent(by: 2))
                            """

                        XCTFail("""
                        Received unexpected action: …

                        \(diff)
                        """, file: step.file, line: step.line)
                    }
                }
            } catch {
                XCTFail("\(error)", file: step.file, line: step.line)
            }

            if checkState,
               case let expected = debugOutput(expectedState),
               case let actual = debugOutput(store.state),
               expected != actual {
                let diff = RinneTest.diff(expected, actual)
                    .map {
                        """
                        \($0.indent(by: 4))

                          ----
                          (Expected: -, Actual: +)
                        """
                    } ?? """
                    Expected:
                    \(expected.indent(by: 2))

                    Actual:
                    \(actual.indent(by: 2))
                    """

                XCTFail("""
                State change does not match expectation: …

                \(diff)
                """, file: step.file, line: step.line)
            }
        }
    }
}

extension TestScenario {
    public struct Step {
        let kind: Kind
        let file: StaticString
        let line: UInt

        public static func action(_ action: Store.Action,
                                  file: StaticString = #filePath,
                                  line: UInt = #line,
                                  _ closure: @escaping (inout Store.State) throws -> Void = { _ in }) -> Self {
            Step(kind: .action(action, closure), file: file, line: line)
        }

        public static func `do`(file: StaticString = #filePath,
                                line: UInt = #line,
                                _ closure: @autoclosure @escaping () throws -> Void,
                                _ then: @escaping (inout Store.State) throws -> Void = { _ in }) -> Self {
            Step(kind: .do(closure, then: then), file: file, line: line)
        }

        public static func then(file: StaticString = #filePath,
                                line: UInt = #line,
                                _ closure: @escaping (inout Store.State) throws -> Void) -> Self {
            Step(kind: .then(closure), file: file, line: line)
        }

        public static func receive(event: Store.Event,
                                   file: StaticString = #filePath,
                                   line: UInt = #line) -> Self {
            Step(kind: .receive(event: event), file: file, line: line)
        }

        enum Kind {
            case action(Store.Action, (inout Store.State) throws -> Void)
            case `do`(() throws -> Void, then: (inout Store.State) throws -> Void)
            case then((inout Store.State) throws -> Void)
            case receive(event: Store.Event)
        }
    }
}

#endif
