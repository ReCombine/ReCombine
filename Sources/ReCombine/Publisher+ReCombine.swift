//
//  Publisher+ReCombine.swift
//  
//
//  Created by Crowson, John on 12/17/19.
//

import Combine

extension Publisher where Self.Output : Action {
    /// Wraps this publisher with a type eraser to return a generic `Action` protocol.
    ///
    /// Use to expose a generic `Action`, rather than this publisher’s actual Action implementer.
    /// This will help satisfy constraints for Publishers that are expected to be of type `Action`.
    /// ```
    /// // Below: Error: Cannot convert value of type 'AnyPublisher<GetPost, Never>' to specified type 'AnyPublisher<Action, Never>'
    /// let actionPublisher: AnyPublisher<Action, Never> = actions
    ///     .ofType(GetPost.self)
    ///     .handleEvents(receiveOutput: { _ in print("Got it") })
    ///     .eraseToAnyPublisher()
    /// // Below: No error with eraseActionType()
    /// let actionPublisher: AnyPublisher<Action, Never> = actions
    ///     .ofType(GetPost.self)
    ///     .handleEvents(receiveOutput: { _ in print("Got it") })
    ///     .eraseActionType()
    ///     .eraseToAnyPublisher()
    /// ```
    public func eraseActionType() -> Publishers.Map<Self, Action> {
        return map({ action in action as Action })
    }
}

extension AnyPublisher where Output == Action {
    /// Filter that includes only the `Action` type that is given, and maps to that specific Action type.
    ///
    /// The code block converts the action stream from `AnyPublisher<Action, Never>` to `AnyPublisher<GetPost, Never>`:
    /// ```
    /// let getPostOnly: AnyPublisher<GetPost, Never> = actions
    ///     .ofType(GetPost.self)
    ///     .eraseToAnyPublisher()
    /// ```
    public func ofType<A: Action>(_: A.Type) -> Publishers.CompactMap<Self, A> {
        return compactMap({ action in action as? A })
    }

    /// Filter that includes only the two `Action` types that are given.
    ///
    /// ```
    /// actions
    ///     .ofType(Action1.self, Action2.self)
    ///     .map { action in /* action will be of type Action1 or Action2 */ }
    /// ```
    public func ofTypes<
        A1: Action,
        A2: Action
        >(_: A1.Type,
          _: A2.Type
    ) -> Publishers.CompactMap<Self, Action> {
        return compactMap({ action in
            if let actionType1 = action as? A1 {
                return actionType1
            } else if let actionType2 = action as? A2 {
                return actionType2
            } else {
                return nil
            }
        })
    }

    /// Filter that includes only the three `Action` types that are given.
    ///
    /// ```
    /// actions
    ///     .ofType(Action1.self, Action2.self, Action3.self)
    ///     .map { action in /* action will be of type Action1, Action2, or Action3 */ }
    /// ```
    public func ofTypes<
        A1: Action,
        A2: Action,
        A3: Action
        >(_: A1.Type,
          _: A2.Type,
          _: A3.Type
    ) -> Publishers.CompactMap<Self, Action> {
        return compactMap({ action in
            if let actionType1 = action as? A1 {
                return actionType1
            } else if let actionType2 = action as? A2 {
                return actionType2
            } else if let actionType3 = action as? A3 {
                return actionType3
            } else {
                return nil
            }
        })
    }

    /// Filter that includes only the four `Action` types that are given.
    ///
    /// ```
    /// actions
    ///     .ofType(Action1.self, Action2.self, Action3.self, Action4.self)
    ///     .map { action in /* action will be of type Action1, Action2, Action3, or Action4 */ }
    /// ```
    public func ofTypes<
        A1: Action,
        A2: Action,
        A3: Action,
        A4: Action
        >(_: A1.Type,
          _: A2.Type,
          _: A3.Type,
          _: A4.Type
    ) -> Publishers.CompactMap<Self, Action> {
        return compactMap({ action in
            if let actionType1 = action as? A1 {
                return actionType1
            } else if let actionType2 = action as? A2 {
                return actionType2
            } else if let actionType3 = action as? A3 {
                return actionType3
            } else if let actionType4 = action as? A4 {
                return actionType4
            } else {
                return nil
            }
        })
    }

    /// Filter that includes only the five `Action` types that are given.
    ///
    /// ```
    /// actions
    ///     .ofType(Action1.self, Action2.self, Action3.self, Action4.self, Action5.self)
    ///     .map { action in /* action will be of type Action1, Action2, Action3, Action4, or Action5 */ }
    /// ```
    public func ofTypes<
        A1: Action,
        A2: Action,
        A3: Action,
        A4: Action,
        A5: Action
        >(_: A1.Type,
          _: A2.Type,
          _: A3.Type,
          _: A4.Type,
          _: A5.Type
    ) -> Publishers.CompactMap<Self, Action> {
        return compactMap({ action in
            if let actionType1 = action as? A1 {
                return actionType1
            } else if let actionType2 = action as? A2 {
                return actionType2
            } else if let actionType3 = action as? A3 {
                return actionType3
            } else if let actionType4 = action as? A4 {
                return actionType4
            } else if let actionType5 = action as? A5 {
                return actionType5
            } else {
                return nil
            }
        })
    }
}
