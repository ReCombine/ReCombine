//
//  File.swift
//  
//
//  Created by Kristin on 1/29/20.
//

import ReCombine
import Combine

/// Initial `Action` dispatched by a `MockStore`.  Denotes that no action has been to the `MockStore` instance yet.
public struct NoopAction: Action {}

/// Mock `Store` for testing that allows updating the `Store` to a specific state without dispatching actions.
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
open class MockStore<S>: Store<S> {
    
    private var mockState: S
    private var mockStateSubject: CurrentValueSubject<S, Never>
    public var actionSubject: CurrentValueSubject<Action, Never>
    
    public init(state: S) {
        mockState = state
        mockStateSubject = CurrentValueSubject(state)
        actionSubject = CurrentValueSubject(NoopAction())
        super.init(reducer: { state, _ in state }, initialState: state)
    }
    
    public func setState(_ state: S) {
        mockState = state
        mockStateSubject.send(state)
    }
    
    public override func receive<T>(subscriber: T) where T: Subscriber, Failure == T.Failure, Output == T.Input {
        mockStateSubject.receive(subscriber: subscriber)
    }
    
    public override func dispatch(action: Action) {
        actionSubject.send(action)
    }
}
