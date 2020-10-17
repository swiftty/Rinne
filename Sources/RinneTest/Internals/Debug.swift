import Foundation

func debugOutput(_ value: Any, indent: Int = 0) -> String {
    var visitedItems: Set<ObjectIdentifier> = []

    func tuplify(_ children: Mirror.Children) -> String {
        children
            .map { child -> String in
                let label = child.label ?? ""
                return "\(label.hasPrefix(".") ? "" : "\(label): ")\(inner(child.value))"
            }
            .joined(separator: ",\n")
    }

    func inner(_ value: Any, indent: Int = 0) -> String {
        let mirror = Mirror(reflecting: value)
        switch (value, mirror.displayStyle) {
        case (_, .collection):
            return """
            [
            \(mirror.children.map { inner($0.value, indent: 4) }.joined(separator: ",\n"))
            ]
            """.indent(by: indent)

        case (_, .dictionary):
            let pairs = mirror.children.map { _, value -> String in
                let pair = value as! (key: AnyHashable, value: Any)
                return """
                \(inner(pair.key.base)): \(inner(pair.value))
                """.indent(by: 4)
            }
            return """
            [
            \(pairs.sorted().joined(separator: ",\n"))
            ]
            """.indent(by: indent)

        case (_, .set):
            return """
            Set([
            \(mirror.children.map { inner($0.value, indent: 4) }.sorted().joined(separator: ",\n"))
            ])
            """

        case (_, .optional):
            guard let child = mirror.children.first else {
                return "nil".indent(by: indent)
            }
            return inner(child.value, indent: indent)

        case (_, .enum):
            guard let child = mirror.children.first else {
                return """
                \(mirror.subjectType).\(value)
                """.indent(by: indent)
            }

            let childMirror = Mirror(reflecting: child.value)
            let elements = childMirror.displayStyle != .tuple
                ? inner(child.value, indent: 4)
                : tuplify(childMirror.children).indent(by: 4)
            return """
            \(mirror.subjectType).\(child.label ?? "")(
            \(elements)
            )
            """.indent(by: indent)

        case (_, .struct) where !mirror.children.isEmpty:
            let elements = mirror.children
                .map { "\($0.label.map { "\($0): " } ?? "")\(inner($0.value))".indent(by: 4) }
                .joined(separator: ",\n")
            if mirror.subjectType is AnyHashable.Type {
                return elements.indent(by: indent)
            }
            return """
            \(mirror.subjectType)(
            \(elements)
            )
            """.indent(by: indent)

        case (let value as AnyObject, .class)
                where !mirror.children.isEmpty && !visitedItems.contains(ObjectIdentifier(value)):
            visitedItems.insert(ObjectIdentifier(value))
            let elements = mirror.children
                .map { "\($0.label.map { "\($0): " } ?? "")\(inner($0.value))".indent(by: 4) }
                .joined(separator: ",\n")
            return """
            \(mirror.subjectType)(
            \(elements)
            )
            """.indent(by: indent)

        case (let value as AnyObject, .class)
                where !mirror.children.isEmpty && visitedItems.contains(ObjectIdentifier(value)):
            return """
            \(mirror.subjectType)(↩︎)
            """.indent(by: indent)

        case (_, .struct), (_, .class):
            return """
            \(mirror.subjectType)()
            """.indent(by: indent)

        case (_, .tuple) where mirror.children.isEmpty:
            return "()".indent(by: indent)

        case (_, .tuple):
            let elements = tuplify(mirror.children)
            return elements.indent(by: indent)

        case (let value as AnyHashable, nil) where mirror.subjectType is AnyHashable.Type:
            return inner(value.base, indent: indent)

        case (let value as CustomDebugStringConvertible, _):
            return value.debugDescription
                .replacingOccurrences(of: #"^<([^:]+): 0x[^>]+>$"#, with: "$1()", options: .regularExpression)
                .indent(by: indent)

        case (let value as CustomStringConvertible, _):
            return value.description
                .indent(by: indent)

        case (_, nil):
            return "\(value)".indent(by: indent)

        default:
            return "\(value)".indent(by: indent)
        }
    }

    return inner(value, indent: indent)
}

extension String {
    func indent(by n: Int) -> String {
        let space = String(repeating: " ", count: n)
        return space + replacingOccurrences(of: "\n", with: "\n\(space)")
    }
}
