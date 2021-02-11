import Foundation
import Combine

private let cancellablesLock = NSRecursiveLock()
private var cancellables: [AnyHashable: Set<AnyCancellable>] = [:]

extension Effect {
    public func cancellable<H: Hashable>(_ id: H, inFlight: Bool = false) -> Effect {
        typealias Subject = PassthroughSubject<Output, Failure>
        let effect = Deferred<Publishers.HandleEvents<Subject>> { [self] in
            cancellablesLock.lock()
            defer { cancellablesLock.unlock() }

            let subject = Subject()
            let _cancellable = subscribe(subject)  // swiftlint:disable:this identifier_name

            var cancellable: AnyCancellable!
            cancellable = AnyCancellable {
                cancellablesLock.lock()
                defer { cancellablesLock.unlock() }

                subject.send(completion: .finished)
                _cancellable.cancel()
                cancellables[id]?.remove(cancellable)
                if cancellables[id]?.isEmpty ?? false {
                    cancellables[id] = nil
                }
            }

            cancellables[id, default: []].insert(cancellable)

            return subject.handleEvents(
                receiveCompletion: { _ in cancellable.cancel() },
                receiveCancel: cancellable.cancel
            )
        }

        return inFlight
            ? Self.cancel(id).append(effect).eraseToEffect()
            : effect.eraseToEffect()
    }

    public static func cancel<H: Hashable>(_ id: H) -> Effect {
        return Deferred<Empty<Output, Failure>> {
            cancellablesLock.lock()
            defer { cancellablesLock.unlock() }

            cancellables[id]?.forEach { $0.cancel() }
            return Empty(completeImmediately: true)
        }.eraseToEffect()
    }
}
