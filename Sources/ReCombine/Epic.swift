//
//  Epic.swift
//  
//
//  Created by RORY KELLY on 15/09/2021.
//

import Foundation
import Combine
import CombineExt

/// Configures an Epic from a source function and a dispatch option.
///
/// Epic are used for side-effects in ReCombine applications, but allow acess to the current state of the store. See https://redux-observable.js.org/docs/basics/Epics.html for a js implementation
public struct Epic<S> {
    /// When true, the emitted actions from the `source` Action Publisher will be dispatched to the store.  If false, the emitted actions will be ignored.
    public let dispatch: Bool
    /// A closure with takes in a State Publisher , an Action Publisher and returns an Action Publisher
    public let source: (CurrentValueSubject<S, Never>, AnyPublisher<Action, Never>) -> AnyPublisher<Action, Never>
}
