//
//  MockStore.swift
//  ReCombineTest
//
//  Created by Crowson, John on 12/10/19.
//  Copyright © 2019 Crowson, John.
//  Licensed under Apache License 2.0
//

import ReCombine
import Combine

/// Initial `Action` dispatched emitted by the `MockStore` `actionSubject`.  Denotes that no action has been dispatched to the `MockStore` instance yet.
public struct NoopAction: Action {}

/// Mock `Store` for testing that allows updating the `Store` to a specific state without dispatching actions.  Allows tests to "spy" on dispatched Actions.
///
/// ```
/// struct ViewModel {
///   // ...
///   init(store: Store<AppState> = store) {
///     // ...
///   }
/// }
///
/// class ViewModelTests: XCTestCase {
///
///   let mockStore = MockStore(state: AppState())
///
///   override func setUp() {
///     let viewModel = ViewModel(store: mockStore)
///   }
///
///   func testSomething() {
///     let otherMockState = // ...
///     mockStore.setState(otherMockState)
///     // ...
///   }
/// }
public class MockStore<S>: Store<S> {
    
    private var mockState: S
    private var mockStateSubject: CurrentValueSubject<S, Never>
    private var mockActionSubject: CurrentValueSubject<Action, Never>
    public let dispatchedActions: AnyPublisher<Action, Never>
    
    public init(state: S) {
        mockState = state
        mockStateSubject = CurrentValueSubject(state)
        mockActionSubject = CurrentValueSubject(NoopAction())
        dispatchedActions = mockActionSubject.eraseToAnyPublisher()
        super.init(reducer: { state, _ in state }, initialState: state)
    }
    
    public func setState(_ state: S) {
        mockState = state
        mockStateSubject.send(state)
    }
    
    public override func dispatch(action: Action) {
        mockActionSubject.send(action)
    }
    
    public override func receive<T>(subscriber: T) where T: Subscriber, Failure == T.Failure, Output == T.Input {
        mockStateSubject.receive(subscriber: subscriber)
    }
    
    public override func register(_ effect: Effect) -> AnyCancellable {
        return effect.source(mockActionSubject.eraseToAnyPublisher())
            .filter { _ in return effect.dispatch }
            .sink(receiveValue: { [weak self] action in self?.dispatch(action: action) })
    }
}
