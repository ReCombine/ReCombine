//
//  Effect.swift
//  
//
//  Created by Crowson, John on 12/17/19.
//

import Combine

/// Configures an Effect from a source function and a dispatch option.
///
/// Effects are used for side-effects in ReCombine applications.  See the Architecture section of the official documentation for more.
/// ```
/// let successEffect = Effect(dispatch: false) { (actions: AnyPublisher<Action, Never>) -> AnyPublisher<Action, Never> in
///    actions
///     .ofType(GetPostsSuccess.self)
///     .handleEvents(receiveOutput: { _ in print("Got it") })
///     .eraseActionType()
///     .eraseToAnyPublisher()
/// }
/// ```
public struct Effect {
    /// When true, the emitted actions from the `source` Action Publisher will be dispatched to the store.  If false, the emitted actions will be ignored.
    public let dispatch: Bool
    /// A closure with takes in an Action Publisher and returns an Action Publisher
    public let source: (AnyPublisher<Action, Never>) -> AnyPublisher<Action, Never>
    /// Initializes an Effect
    public init(dispatch: Bool, _ source: @escaping (AnyPublisher<Action, Never>) -> AnyPublisher<Action, Never>) {
        self.dispatch = dispatch
        self.source = source
    }
}
