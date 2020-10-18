import XCTest
@testable import RinneTest

private struct S {
    var intValue = 0
    var stringValue = "string"
    var computed: Int { intValue }
}

private enum E {
    case noValue
    case intValue(Int)
    case intNamedValue(value: Int)
    case multiple(String, bool: Bool)
}

private class C {
    var intValue = 0
    var stringValue = "string"
    var c: C? = nil
    var computed: Int { intValue }
}

final class DebugTests: XCTestCase {
    func testPrimitive() {
        XCTAssertEqual(debugOutput(1), "1")
        XCTAssertEqual(debugOutput(false), "false")
        XCTAssertEqual(debugOutput("foo"), #""foo""#)
        XCTAssertEqual(debugOutput(3.14159), "3.14159")

        XCTAssertEqual(debugOutput([1, 2]), """
        [
            1,
            2
        ]
        """)

        XCTAssertEqual(debugOutput(["a": 1.1, "b": 2.2]), """
        [
            "a": 1.1,
            "b": 2.2
        ]
        """)
    }

    func testStruct() {
        struct Empty {}

        XCTAssertEqual(debugOutput(Empty()), "Empty()")
        XCTAssertEqual(debugOutput(S()), """
        S(
            intValue: 0,
            stringValue: "string"
        )
        """)
    }

    func testEnum() {
        XCTAssertEqual(debugOutput(E.noValue), "E.noValue")
        XCTAssertEqual(debugOutput(E.intValue(100)), """
        E.intValue(
            100
        )
        """)
        XCTAssertEqual(debugOutput(E.intNamedValue(value: 10)), """
        E.intNamedValue(
            value: 10
        )
        """)
        XCTAssertEqual(debugOutput(E.multiple("string", bool: true)), """
        E.multiple(
            "string",
            bool: true
        )
        """)
    }

    func testClass() {
        class Empty {}

        XCTAssertEqual(debugOutput(Empty()), "Empty()")
        XCTAssertEqual(debugOutput(C()), """
        C(
            intValue: 0,
            stringValue: "string",
            c: nil
        )
        """)

        let c = C()
        c.c = c
        XCTAssertEqual(debugOutput(c), """
        C(
            intValue: 0,
            stringValue: "string",
            c: C(↩︎)
        )
        """)
    }
}
