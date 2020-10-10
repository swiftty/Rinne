import Combine

extension Effect {
    public static func just(_ value: Output) -> Self {
        .init(value: value)
    }

    public static func future(_ completion: @escaping (@escaping (Result<Output, Failure>) -> Void) -> Void) -> Self {
        Deferred {
            Future { callback in
                completion { result in callback(result) }
            }
        }
        .eraseToEffect()
    }

    public static func merge<P>(_ ps: P...) -> Effect<P.Output, P.Failure>
    where P: Publisher,
          P.Output == Output,
          P.Failure == Failure {
        Publishers.MergeMany(ps).eraseToEffect()
    }
}

extension Effect {
    public static func merge<A, B>(_ a: A,
                                   _ b: B) -> Effect<A.Output, A.Failure>
    where A: Publisher, B: Publisher,
          A.Output == B.Output,
          A.Failure == B.Failure {
        Publishers.Merge(a, b).eraseToEffect()
    }

    public static func merge<A, B, C>(_ a: A,
                                      _ b: B,
                                      _ c: C) -> Effect<A.Output, A.Failure>
    where A: Publisher, B: Publisher, C: Publisher,
          A.Output == B.Output,
          A.Failure == B.Failure,
          A.Output == C.Output,
          A.Failure == C.Failure {
        Publishers.Merge3(a, b, c).eraseToEffect()
    }

    public static func merge<A, B, C, D>(_ a: A,
                                         _ b: B,
                                         _ c: C,
                                         _ d: D) -> Effect<A.Output, A.Failure>
    where A: Publisher, B: Publisher, C: Publisher, D: Publisher,
          A.Output == B.Output,
          A.Failure == B.Failure,
          A.Output == C.Output,
          A.Failure == C.Failure,
          A.Output == D.Output,
          A.Failure == D.Failure {
        Publishers.Merge4(a, b, c, d).eraseToEffect()
    }

    public static func merge<A, B, C, D, E>(_ a: A,
                                            _ b: B,
                                            _ c: C,
                                            _ d: D,
                                            _ e: E) -> Effect<A.Output, A.Failure>
    where A: Publisher, B: Publisher, C: Publisher, D: Publisher, E: Publisher,
          A.Output == B.Output,
          A.Failure == B.Failure,
          A.Output == C.Output,
          A.Failure == C.Failure,
          A.Output == D.Output,
          A.Failure == D.Failure,
          A.Output == E.Output,
          A.Failure == E.Failure {
        Publishers.Merge5(a, b, c, d, e).eraseToEffect()
    }
}
