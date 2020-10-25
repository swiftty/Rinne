import SwiftUI
import Combine
import Rinne

///
///
///
public protocol StoreBindable: ObservableObject {
    associatedtype State
    associatedtype Action

    var state: State { get }
    var action: ActionSubject<Action> { get }
}

extension StoreBindable {
    @inlinable
    public var binding: Bindings<Self> { Bindings(self) }
}

@dynamicMemberLookup
public struct Bindings<Store: StoreBindable> {
    public struct BindingFunction<T> {
        @usableFromInline
        let getter: () -> T

        @usableFromInline
        let setter: (Store.Action) -> Void

        @usableFromInline
        init(get: @escaping () -> T, set: @escaping (Store.Action) -> Void) {
            getter = get
            setter = set
        }

        @inlinable
        public func callAsFunction(action: @escaping (T) -> Store.Action) -> Binding<T> {
            Binding(get: getter, set: { setter(action($0)) })
        }
    }

    @usableFromInline
    let store: Store

    @inlinable
    public subscript <T>(dynamicMember keyPath: KeyPath<Store.State, T>) -> BindingFunction<T> {
        BindingFunction(
            get: { [unowned store] in store.state[keyPath: keyPath] },
            set: { [unowned store] in store.action.send($0) }
        )
    }

    @usableFromInline
    init(_ store: Store) {
        self.store = store
    }
}
