//
//  Store.swift
//  ReCombine
//
//  Created by Crowson, John on 12/10/19.
//  Copyright © 2019 Crowson, John.
//  Licensed under Apache License 2.0
//

import Combine

/// Protocol that all action's must implement.
///
/// Example implementation:
/// ```
/// struct GetPostSuccess: Action {
///     let post: Post
/// }
/// ```
public protocol Action {}

/// A generic representation of a reducer function.
///
/// Reducer functions are pure functions which take a State and Action and return a State.
/// ```
/// let reducer: ReducerFn = { (state: State, action: Action) in
///     var state = state
///     switch action {
///         case let action as SetScores:
///             state.home = action.game.home
///             state.away = action.game.away
///             return state
///         default:
///             return state
///     }
/// }
/// ```
public typealias ReducerFn<S> = (S, Action) -> S

/// A generic representation of a selector function.
///
/// Selector functions are pure functions which take a State and return data derived from that State.
/// ```
/// let selectPost = { (state: AppState) in
///     return state.singlePost.post
/// }
/// ```
public typealias SelectorFn<S, V> = (S) -> V

/// Combine-based state management.  Enables dispatching of actions, executing reducers, performing side-effects, and listening for the latest state.
///
/// Implements the `Publisher` protocol, allowing direct subscription for the latest state.
/// ```
/// import ReCombine
/// import Combine
///
/// struct CounterView {
///     struct Increment: Action {}
///     struct Decrement: Action {}
///
///     struct State {
///         var count = 0
///     }
///
///     static func reducer(state: State, action: Action) -> State {
///         var state = state
///         switch action {
///             case _ as Increment:
///                 state.count += 1
///                 return state
///             case _ as Decrement:
///                 state.count -= 1
///                 return state
///             default:
///                 return state
///         }
///     }
///
///     static let effect = Effect(dispatch: false)  { (actions: AnyPublisher<Action, Never>) in
///         actions.ofTypes(Increment.self, Decrement.self).print("Action Dispatched").eraseToAnyPublisher()
///     }
/// }
///
/// let store = Store(reducer: CounterView.reducer, initialState: CounterView.State(), effects: [CounterView.effect])
/// ```
open class Store<S>: Publisher {
    /// Publisher protocol - emits the state :nodoc:
    public typealias Output = S
    /// Publisher protocol :nodoc:
    public typealias Failure = Never

    private var state: S
    private var stateSubject: CurrentValueSubject<S, Never>
    private var actionSubject: PassthroughSubject<Action, Never>
    private var cancellableSet: Set<AnyCancellable> = []
    private let reducer: ReducerFn<S>

    /// Creates a new Store.
    /// - Parameter reducer: a single reducer function which will handle reducing state for all actions dispatched to the store.
    /// - Parameter initialState: the initial state.  This state will be used by consumers before the first action is dispatched.
    /// - Parameter effects: action based side-effects.  Each `Effect` element is processed for the lifetime of the `Store` instance.
    public init(reducer: @escaping ReducerFn<S>, initialState: S, effects: [Effect] = []) {
        self.reducer = reducer
        state = initialState
        stateSubject = CurrentValueSubject(initialState)
        actionSubject = PassthroughSubject()

        for effect in effects {
            // Effects registered through init are maintained for the lifecycle of the Store.
            register(effect).store(in: &cancellableSet)
        }
    }

    /// Dispatch `Action` to the Store.  Calls reducer function with the passed `action` and previous state to generate a new state.
    /// - Parameter action: action to call the reducer with.
    ///
    /// Dispatching an action to the Store:
    /// ```
    /// struct Increment: Action {}
    ///
    /// store.dispatch(action: Increment())
    /// ```
    open func dispatch(action: Action) {
        state = reducer(state, action)
        stateSubject.send(state)
        actionSubject.send(action)
    }

    /// Returns derived data from the application state based on a given selector function.
    ///
    /// Selector functions help return view-specific data from a minimum application state.
    ///
    /// **Example:** If a view needs the count of characters in a username, instead of storing both the username and the character count in state, store only the username, and use a selector to retrieve the count.
    /// ```
    /// store.select({ (state: AppState) in state.username.count })
    /// ```
    /// To enable reuse, abstract the closure into a separate property.
    /// ```
    /// let selectUsernameCount = { (state: AppState) in state.username.count }
    /// // ...
    /// store.select(selectUsernameCount)
    /// ```
    public func select<V: Equatable>(_ selector: @escaping (S) -> V) -> AnyPublisher<V, Never> {
        return map(selector).removeDuplicates().eraseToAnyPublisher()
    }

    /// Publisher protocol - use the internal stateSubject under the hood :nodoc:
    open func receive<T>(subscriber: T) where T: Subscriber, Failure == T.Failure, Output == T.Input {
        stateSubject.receive(subscriber: subscriber)
    }
    
    /// Registers an effect that processes from when this function is called until the returned `AnyCancellable` instance in cancelled.
    ///
    /// This can be useful for:
    /// 1. Effects that should not process for the entire lifetime of the `Store` instance.
    /// 2. Effects that need to capture a particular scope in it's `source` closure.
    ///
    /// The following SwiftUI example shows these uses:
    /// 1. Processing the `showAlert` `Effect` for the lifetime of the `Model` only.  This is done by storing the returned `AnyCancellable` instance in `cancellableSet`.  Because `cancellableSet` is a instance of `Set<AnyCancellable>`, it will automatically call `cancel()` when on each element when `Model` is deinitialized.
    /// 2. Capturing `self` inside the `showAlert` Effect's source closure.
    /// ```
    /// class Model: ObservableObject {
    ///     @Published var showAlert: Bool = false
    ///     private var cancellableSet: Set<AnyCancellable> = []
    ///
    ///     init(store: Store<GetPostError>) {
    ///         let showAlertOnError = Effect(dispatch: false) { actions in
    ///             actions.ofType(GetPostError.self)
    ///                 .handleEvents(receiveOutput: { [weak self] _ in
    ///                     self?.showAlert = true
    ///                 })
    ///                 .eraseActionType()
    ///                 .eraseToAnyPublisher()
    ///         }
    ///         store.register(showAlertOnError)
    ///     }
    /// }
    /// ```
    /// - Parameter effect: action based side-effect.  It is processed until the returned `AnyCancellable` instance is cancelled.
    open func register(_ effect: Effect) -> AnyCancellable {
        return effect.source(actionSubject.eraseToAnyPublisher())
            .filter { _ in return effect.dispatch }
            .sink(receiveValue: { [weak self] action in self?.dispatch(action: action) })
    }
}
