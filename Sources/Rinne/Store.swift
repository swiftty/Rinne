import Combine
import Foundation

public typealias Store<S: _StoreType> = _Store<S.State, S.Action, S.Mutation, S.Event, S.Environment> & _StoreType

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
    associatedtype Mutation = Action
    associatedtype Event = Never
    associatedtype Environment

    var action: ActionSubject<Action> { get }
    var events: AnyPublisher<Event, Never> { get }
    var state: State { get }

    func reduce(state: inout State, mutation: Mutation) -> Effect<Event, Never>
    func mutate(action: Action, environment: Environment) -> Effect<Mutation, Never>

    func poll(environment: Environment) -> Effect<Mutation, Never>
    func poll(state: Published<State>.Publisher, environment: Environment) -> Effect<Mutation, Never>
}

extension _StoreType {
    public func poll(environment: Environment) -> Effect<Mutation, Never> { nil }

    public func poll(state: Published<State>.Publisher, environment: Environment) -> Effect<Mutation, Never> { nil }
}

extension _StoreType {
    private typealias _Store = Rinne._Store<State, Action, Mutation, Event, Environment>

    public func _attach(environment: Any) {
        guard let store = self as? _Store, !store.isAttached,
              let environment = environment as? Environment else { return }

        let scheduler = MainThreadScheduler()
        Publishers
            .Merge3(
                poll(environment: environment),
                poll(state: store.$state, environment: environment),
                store.action
                    .receive(on: scheduler)
                    .flatMap { [weak self] action in
                        self?.mutate(action: action, environment: environment) ?? .none
                    }
            )
            .receive(on: scheduler)
            .flatMap { [weak self] mutation in
                self?.perform(mutation: mutation) ?? .none
            }
            .sink(receiveValue: { [weak store] event in
                store?._events.send(event)
            })
            .store(in: &store.cancellables)
    }

    private func perform(mutation: Mutation) -> Effect<Event, Never> {
        guard let store = self as? _Store else { return nil }

        return reduce(state: &store.state, mutation: mutation)
    }
}

///
///
///
open class _Store<State, Action, Mutation, Event, Environment> {
    @Published public internal(set) var state: State

    public let action = ActionSubject<Action>()
    public private(set) lazy var events: AnyPublisher<Event, Never> = _events.eraseToAnyPublisher()
    let _events = PassthroughSubject<Event, Never>()

    var cancellables: Set<AnyCancellable> = []
    var isAttached = false

    public init(initialState: State, environment: Environment) {
        state = initialState
        (self as! _AnyStoreType)._attach(environment: environment)
        isAttached = true
    }
}


@dynamicMemberLookup
public protocol StatePublisher: Publisher {
    subscript <T>(dynamicMember keyPath: KeyPath<Output, T>) -> Publishers.MapKeyPath<Self, T> { get }
}

extension StatePublisher {
    public subscript <T>(dynamicMember keyPath: KeyPath<Output, T>) -> Publishers.MapKeyPath<Self, T> {
        map(keyPath)
    }
}

extension Published.Publisher: StatePublisher {}
