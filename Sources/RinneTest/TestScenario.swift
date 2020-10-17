#if canImport(XCTest)

import XCTest
import Combine
import Rinne

public final class TestScenario<Store: _StoreType> {
    private let store: () -> Store

    public init(_ store: @autoclosure @escaping () -> Store) {
        self.store = store
    }

    public func callAsFunction(_ steps: Step...) {
        callAsFunction(steps)
    }

    public func callAsFunction(_ steps: [Step]) {
        let store = self.store()
        var expectedState = store.state

        for step in steps {
            do {
                switch step.kind {
                case .action(let action, let update):
                    store.action.send(action)
                    try update(&expectedState)

                case .do(let work, let then):
                    try work()
                    try then(&expectedState)

                case .then(let update):
                    try update(&expectedState)
                }
            } catch {
                XCTFail("\(error)", file: step.file, line: step.line)
            }

            if case let expected = debugOutput(expectedState),
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

                XCTFail(
                    """
                    State change does not match expectation: …

                    \(diff)
                    """,
                    file: step.file,
                    line: step.line
                )
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

        enum Kind {
            case action(Store.Action, (inout Store.State) throws -> Void)
            case `do`(() throws -> Void, then: (inout Store.State) throws -> Void)
            case then((inout Store.State) throws -> Void)
        }
    }
}

#endif
