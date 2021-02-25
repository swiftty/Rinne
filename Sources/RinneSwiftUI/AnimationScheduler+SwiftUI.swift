import Rinne
import Combine
import SwiftUI

extension AnyScheduler {
    public func animation(_ animation: Animation? = .default) -> Self {
        Self.init(self) { action in
            withAnimation(animation, action)
        }
    }
}

extension AnyScheduler {
    public func transaction(_ transaction: Transaction) -> Self {
        Self.init(self) { action in
            withTransaction(transaction, action)
        }
    }
}
