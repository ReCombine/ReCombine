import Combine
import ReCombine
import SwiftUI

struct CounterState {
    var count = 0
}

struct Increment: Action {}
struct Decrement: Action {}
struct Reset: Action {}

func reducer(state: CounterState, action: Action) -> CounterState {
    var state = state
    switch action {
        case _ as Increment:
            state.count += 1
            return state
        case _ as Decrement:
            state.count -= 1
            return state
        case _ as Reset:
            state.count = 0
            return state
        default:
            return state
    }
}

let counterStore = Store(reducer: reducer, initialState: CounterState())

func getCountString(state: CounterState) -> String {
    return "Current Count: \(String(state.count))"
}

class CounterViewModel: ObservableObject {
    @Published var showResetAlert = false
    @Published var countString = ""
    private let store: Store<CounterState>
    private var cancellableSet: Set<AnyCancellable> = []
    
    init(store: Store<CounterState> = counterStore) {
        self.store = store
        store.select(getCountString)
            .assign(to: \.countString, on: self)
            .store(in: &cancellableSet)
        let showAlertOnReset = Effect(dispatch: false) { actions in
            actions.ofType(Reset.self)
                .handleEvents(receiveOutput: { [weak self] _ in
                    self?.showResetAlert = true
                })
                .eraseActionType()
                .eraseToAnyPublisher()
        }
        store.register(showAlertOnReset)
            .store(in: &cancellableSet)
    }
    
    func incrementTapped() {
        store.dispatch(action: Increment())
    }
    
    func decrementTapped() {
        store.dispatch(action: Decrement())
    }
    
    func resetTapped() {
        store.dispatch(action: Reset())
    }
}
