import Combine
import Foundation

public typealias Store<S: _StoreType> = _Store<S.State, S.Action, S.Environment> & _StoreType

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
    associatedtype Environment

    func reduce(state: inout State, action: Action, environment: Environment) -> Effect<Action, Never>

    func poll(environment: Environment) -> Effect<Action, Never>
    func poll(state: Published<State>.Publisher, environment: Environment) -> Effect<Action, Never>
    func poll(action: Effect<Action, Never>, environment: Environment) -> Effect<Action, Never>
}

extension _StoreType {
    public func poll(environment: Environment) -> Effect<Action, Never> { nil }

    public func poll(state: Published<State>.Publisher, environment: Environment) -> Effect<Action, Never> { nil }

    public func poll(action: Effect<Action, Never>, environment: Environment) -> Effect<Action, Never> { action }
}

extension _StoreType {
    public func _attach(environment: Any) {
        guard let store = self as? _Store<State, Action, Environment>, !store.isAttached,
              let environment = environment as? Environment else { return }

        Publishers
            .Merge3(
                poll(environment: environment),
                poll(state: store.$state, environment: environment),
                poll(action: store.action.eraseToEffect(), environment: environment))
            .receive(on: MainThreadScheduler())
            .sink { [weak self] action in
                self?.perform(action: action, environment: environment)
            }
            .store(in: &store.cancellables)
    }

    private func perform(action: Action, environment: Environment) {
        guard let store = self as? _Store<State, Action, Environment> else { return }

        if !store.isSending {
            store.synchronousActionsToSend.append(action)
        } else {
            store.bufferedActions.append(action)
            return
        }

        while !store.synchronousActionsToSend.isEmpty || !store.bufferedActions.isEmpty {
            let action = !store.synchronousActionsToSend.isEmpty
                ? store.synchronousActionsToSend.removeFirst()
                : store.bufferedActions.removeFirst()

            store.isSending = true
            let effect = reduce(state: &store.state, action: action, environment: environment)
            store.isSending = false

            var didComplete = false
            let uuid = UUID()

            var isProcessingEffects = true
            let cancellable = effect.sink { [weak store] _ in
                didComplete = true
                store?.effectCancellables[uuid] = nil
            } receiveValue: { [weak store, weak self] action in
                if isProcessingEffects {
                    store?.synchronousActionsToSend.append(action)
                } else {
                    self?.perform(action: action, environment: environment)
                }
            }
            isProcessingEffects = false

            if !didComplete {
                store.effectCancellables[uuid] = cancellable
            }
        }
    }
}

///
///
///
open class _Store<State, Action, Environment> {
    @Published public internal(set) var state: State

    public let action = PassthroughSubject<Action, Never>()

    var isSending = false
    var synchronousActionsToSend: [Action] = []
    var bufferedActions: [Action] = []
    var cancellables: Set<AnyCancellable> = []
    var effectCancellables: [UUID: AnyCancellable] = [:]

    var isAttached = false

    public required init(initialState: State, environment: Environment) {
        state = initialState
        (self as! _AnyStoreType)._attach(environment: environment)
        isAttached = true
    }
}
