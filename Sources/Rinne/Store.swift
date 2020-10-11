import Combine
import Foundation

public typealias Store<S: _StoreType> = _Store<S.State, S.Mutation, S.Action, S.Environment> & _StoreType

///
///
///
public protocol _AnyStoreType: AnyObject {
    func _attach(environment: Any)
}

///
///
///
public protocol _StoreType: _AnyStoreType {
    associatedtype State
    associatedtype Action
    associatedtype Mutation
    associatedtype Environment

    func mutate(action: Action, environment: Environment) -> Effect<Mutation, Never>

    func reduce(state: inout State, mutation: Mutation, environment: Environment)

    func poll(environment: Environment) -> Effect<Mutation, Never>
    func poll(state: Published<State>.Publisher, environment: Environment) -> Effect<Mutation, Never>
}

extension _StoreType {
    public func poll(environment: Environment) -> Effect<Mutation, Never> { nil }

    public func poll(state: Published<State>.Publisher, environment: Environment) -> Effect<Mutation, Never> { nil }
}

extension _StoreType {
    private typealias _Store = Rinne._Store<State, Mutation, Action, Environment>

    public func _attach(environment: Any) {
        guard let store = self as? _Store, !store.isAttached,
              let environment = environment as? Environment else { return }

        Publishers
            .Merge3(
                poll(environment: environment),
                poll(state: store.$state, environment: environment),
                store.action.flatMap { [weak self] action in
                    self?.mutate(action: action, environment: environment) ?? .none
                }
            )
            .receive(on: MainThreadScheduler())
            .sink { [weak self] mutation in
                self?.perform(mutation: mutation, environment: environment)
            }
            .store(in: &store.cancellables)
    }

    private func perform(mutation: Mutation, environment: Environment) {
        guard let store = self as? _Store else { return }

        reduce(state: &store.state, mutation: mutation, environment: environment)
    }
}

///
///
///
open class _Store<State, Mutation, Action, Environment> {
    @Published public internal(set) var state: State

    public let action = ActionSubject<Action>()

    var cancellables: Set<AnyCancellable> = []
    var isAttached = false

    public required init(initialState: State, environment: Environment) {
        state = initialState
        (self as! _AnyStoreType)._attach(environment: environment)
        isAttached = true
    }
}
