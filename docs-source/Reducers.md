# Reducers

Reducers in ReCombine are responsible for handling transitions from one state to the next state in your application. Reducer functions handle these transitions by determining which [actions](./actions.html) to handle based on the action's type.

## Introduction

Reducers are static functions in that they produce the same output for a given input. They are without side effects and handle each state transition synchronously. Each reducer function takes the latest `Action` dispatched, the current state, and determines whether to return a newly modified state or the original state. This guide shows you how to write reducer functions, register them in your `Store`, and compose feature states.

## The reducer function

There are a few consistent parts of every piece of state managed by a reducer.

- A `struct` that defines the shape of the state.
- The arguments including the initial state or current state and the current action.
- The functions that handle state changes for their associated action(s).

Below is an example of a set of actions to handle the state of a scoreboard, and the associated reducer function.

First, define some actions for interacting with a piece of state.

```swift
import ReCombine

struct ScoreboardPage {
    struct HomeScore: Action {}
    struct AwayScore: Action {}
    struct ResetScore: Action {}
    struct SetScore: Action {
        let home: Int
        let away: Int
    }
}
```

Next, create a reducer file that defines a shape for the piece of state.

### Defining the state shape

Each reducer function is a listener of actions. The scoreboard actions defined above describe the possible transitions handled by the reducer.

```swift
import ReCombine

struct ScoreboardPage {
    // Actions...

    struct State {
        var home: Int = 0
        var away: Int = 0
    }
}
```

You define the shape of the state according to what you are capturing, whether it be a single type such as an `Int`, or a more complex object with multiple properties.  Here, the initial values for the `home` and `away` properties of the state are 0.

### Creating the reducer function

The reducer function's responsibility is to handle the state transitions in an immutable way. Create a reducer function that handles the actions for managing the state of the scoreboard.

```swift 
import ReCombine

struct ScoreboardPage {

    // Actions...

    // State...

    static func reducer(state: State, action: Action) -> State {
        var state = state
        switch action {
            case _ as HomeScore:
                state.home += 1
                return state
            case _ as AwayScore:
                state.away += 1
                return state
            case _ as ResetScore:
                state.home = 0
                state.away = 0
                return state
            case let action as SetScore:
                state.home = action.home
                state.away = action.away
                return state
            default:
                return state
        }
    }
}
```

In the example above, the reducer is handling 4 actions: `ScoreboardPage.HomeScore`, `ScoreboardPage.AwayScore`, `ScoreboardPage.ResetScore` and `ScoreboardPage.SetScores`. Each action handles the state transition immutably. This means that the state transitions are not modifying the original state, but are returning a new state. This ensures that a new state is produced with each change, preserving the purity of the change.

When an action is dispatched, _all registered reducers_ receive the action. Whether they handle the action is determined by the switch case statements that associate one or more actions with a given state change.

## Registering state

The state of an application is defined by a single type, encompassing substates as properties. If the state is small and unnested, accompanied by only a few actions (this is the case in the counter example above), you may only need to register a single reducer function. 

> **Note**: Creating the `Store` in the `AppDelegate` or in a global scope ensures that the states are defined upon application startup.

### Single reducer function

To register the global `Store` within your application with only one reducer, reference the reducer directly.

```swift
import ReCombine

let store = Store(reducer: ScoreboardPage.reducer, initialState: ScoreboardPage.State())
```

### Multiple reducer functions

As your application state becomes more complex, accompanied by more actions for your reducer to handle, it is suggested to break your reducer up into several independent reducers, with each handling a single key of your state.  To register the global `Store` within your application with multiple reducers, use `combineReducers(_:)` with `forKey(_:use:)` for each key that define your state.

```swift
import ReCombine

struct AppState {
    var scoreboard = ScoreboardPage.State()
    var other = OtherPage.State()
}

// Reduce the state using a separate reducer for every state key
let reducers: ReducerFn<AppState> = combineReducers(
    forKey(\.scoreboard, use: ScoreboardPage.reducer),
    forKey(\.other, use: OtherPage.reducer)
)

let store = Store(reducer: reducers, initialState: AppState())
```

In addition to breaking up root state keys into specific reducers, `combineReducers(_:)` can be used for breaking up substate keys as well:

```swift
import ReCombine

struct AppState {
    var scoreboard = ScoreboardPage.State()
    var other = OtherPage.State()
}

// Reduce the substate using a separate reducer for every substate key
let scoreboardReducer: ReducerFn<ScoreboardPage.State> = combineReducers(
    forKey(\.home, use: ScoreboardPage.homeReducer),
    forKey(\.away, use: ScoreboardPage.awayReducer)
)
// Reduce the state using a separate reducer for every state key
let reducers: ReducerFn<AppState> = combineReducers(
    forKey(\.scoreboard, use: scoreboardReducer),
    forKey(\.other, use: OtherPage.reducer)
)

let store = Store(reducer: reducers, initialState: AppState())
```

## Next Steps

Reducers are only responsible for deciding which state transitions need to occur for a given action.

In an application there is also a need to handle non-static (impure) actions, e.g. data requests, in ReCombine we call them [Effects](./effects.html).

