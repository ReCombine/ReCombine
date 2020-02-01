## Key concepts

- [Actions](./actions.html) describe unique events that are dispatched from views and view models.
- State changes are handled by pure functions called [reducers](./reducers.html) that take the current state and the latest action to compute a new state.
- [Selectors](./selectors.html) are pure functions used to select, derive and compose pieces of state.
- State is accessed with the `Store`, a Publishers of state and a Subscribers of actions.

## Installation

Detailed installation instructions can be found on the [Installation](./installation.html) page.

## Diagram

The following diagram represents the overall general flow of application state in ReCombine.

<img src="./img/state-management-lifecycle.png" alt="ReCombine State Management Lifecycle Diagram" width="100%" height="100%" />

## Tutorial

The following tutorial shows you how to manage the state of a counter, and how to select and display it within a SwiftUI iOS application.

1)  Generate a new SwiftUI project and install ReCombine.

2)  Create a new file named `Counter.swift` to describe the counter actions to increment, decrement, and reset its value.

```swift
import ReCombine

enum Counter {
    struct Increment: Action {}
    struct Decrement: Action {}
    struct Reset: Action {}
}
```

3)  Define a state and an associated reducer function to handle changes in the counter value based on the provided actions.

```swift
import ReCombine

enum Counter {
    struct Increment: Action {}
    struct Decrement: Action {}
    struct Reset: Action {}

    struct State {
        var count: Int = 0
    }

    static func reducer(state: State, action: Action) -> State {
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
}
```

4)  In your `AppDelegate` file or in another standalone file, initialize a `Store` that can be accessed throughout your application.  Create and pass a `CounterState` object to be used as the initial state.

```swift
let store = Store(reducer: Counter.reducer, initialState: Counter.State())
```

5)  Create a  `ContentViewModel` class to be used as a view model for the generated  `ContentView`.  Use the globally available `store` to dispatch the Increment, Decrement, and Reset actions. Use the `select` operator with a custom `getCountString`  selector to _select_ the _count_ String from the state.  Use the Combine library's [`assign`](https://developer.apple.com/documentation/combine/publisher/3235801-assign) method to automatically assign the latest value from the selector to the `ContentViewModel`'s `count` property.

```swift
import Combine
import ReCombine
import SwiftUI

class ContentViewModel: ObservableObject {

    @Published var count = ""
    private var cancellableSet: Set<AnyCancellable> = []

    init() {
        store.select(getCountString).assign(to: \.count, on: self).store(in: &cancellableSet)
    }

    func increment() {
        store.dispatch(action: Counter.Increment())
    }

    func decrement() {
        store.dispatch(action: Counter.Decrement())
    }

    func reset() {
        store.dispatch(action: Counter.Reset())
    }
}

let getCountString = { (state: Counter.State) in
    return "Current Count: \(String(state.count))"
}
```

6) Update the `ContentView` with text for the view model's `count` string and buttons to call the increment, decrement, and reset methods.

```swift
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = ContentViewModel()

    var body: some View {
        VStack(alignment: .center) {
            Text(viewModel.count)
            HStack(alignment: .center) {
                Button(action: {
                    self.viewModel.increment()
                }) {
                    Text("Increment")
                }
                Button(action: {
                    self.viewModel.decrement()
                }) {
                    Text("Decrement")
                }
                Button(action: {
                    self.viewModel.reset()
                }) {
                    Text("Reset")
                }
            }
        }
    }
}
```

And that's it! Click the increment, decrement, and reset buttons to change the state of the counter.

Let's cover what you did:

- Defined actions to express events.
- Defined a reducer function to manage the state of the counter.
- Initialize the global state container that is available throughout your application.
- Use the `Store` to dispatch actions and select the current state of the counter.

## Next Steps

Learn about the architecture of an ReCombine application through [actions](./actions.html), [reducers](./reducers.html), and [selectors](./selectors.html).
