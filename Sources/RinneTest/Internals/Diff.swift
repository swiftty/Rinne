func diff(_ first: String, _ second: String) -> String? {
    struct Difference {
        enum Which {
            case both, first, second

            var prefix: StaticString {
                switch self {
                case .both: return "\u{2007}"
                case .first: return "−"
                case .second: return "+"
                }
            }
        }

        let elements: ArraySlice<Substring>
        let which: Which
    }

    func inner(_ first: ArraySlice<Substring>, _ second: ArraySlice<Substring>) -> [Difference] {
        var indicesForLine: [Substring: [Int]] = [:]
        for (i, line) in zip(first.indices, first) {
            indicesForLine[line, default: []].append(i)
        }

        var overlap: [Int: Int] = [:]
        var firstIndex = first.startIndex
        var secondIndex = second.startIndex
        var count = 0

        for (index, secondLine) in zip(second.indices, second) {
            var innerOverlap: [Int: Int] = [:]
            var innerFirstIndex = firstIndex
            var innerSecondIndex = secondIndex
            var innerCount = count

            indicesForLine[secondLine]?.forEach { firstIndex in
                let newCount = (overlap[firstIndex - 1] ?? 0) + 1
                innerOverlap[firstIndex] = newCount
                if newCount > count {
                    innerFirstIndex = firstIndex - newCount + 1
                    innerSecondIndex = index - newCount + 1
                    innerCount = newCount
                }
            }

            overlap = innerOverlap
            firstIndex = innerFirstIndex
            secondIndex = innerSecondIndex
            count = innerCount
        }

        if count == 0 {
            var differences: [Difference] = []
            if !first.isEmpty {
                differences.append(Difference(elements: first, which: .first))
            }
            if !second.isEmpty {
                differences.append(Difference(elements: second, which: .second))
            }
            return differences
        } else {
            var differences = inner(first.prefix(upTo: firstIndex), second.prefix(upTo: secondIndex))
            differences.append(Difference(elements: first.suffix(from: firstIndex).prefix(count), which: .both))
            differences.append(contentsOf: inner(first.suffix(from: firstIndex + count),
                                                 second.suffix(from: secondIndex + count)))
            return differences
        }
    }

    let differences = inner(
        first.split(separator: "\n", omittingEmptySubsequences: false)[...],
        second.split(separator: "\n", omittingEmptySubsequences: false)[...])
    if differences.count == 1, case .both = differences.first?.which { return nil }
    var string = differences.reduce(into: "") { str, diff in
        str += diff.elements.map { "\(diff.which.prefix) \($0)\n" }.joined()
    }
    string.removeLast()
    return string
}
