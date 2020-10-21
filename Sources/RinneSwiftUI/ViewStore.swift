import SwiftUI
import Combine
import Rinne

public typealias ViewStore<T: _StoreType> = Store<T> & _ViewStoreType

///
///
///
public protocol _ViewStoreType: ObservableObject {
    associatedtype State
    associatedtype Action

    var state: State { get }
    var action: ActionSubject<Action> { get }
}

extension _ViewStoreType {
    public func binding<T>(state keyPath: KeyPath<State, T>,
                           action: @escaping (T) -> Action) -> Binding<T> {
        Binding(
            get: { [unowned self] in self.state[keyPath: keyPath] },
            set: { [unowned self] in self.action.send(action($0)) }
        )
    }
}
