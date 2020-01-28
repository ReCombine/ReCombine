# Selectors

Selectors are pure functions used for obtaining slices of store state. ReCombine provides a few helper functions for optimizing this selection. Selectors provide many features when selecting slices of state:

- Portability
- Memoization
- Composition
- Testability
- Type Safety

When using the `createSelector` function ReCombine keeps track of the latest arguments in which your selector function was invoked. Because selectors are [pure functions](https://en.wikipedia.org/wiki/Pure_function), the last result can be returned when the arguments match without reinvoking your selector function. This can provide performance benefits, particularly with selectors that perform expensive computation. This practice is known as [memoization](https://en.wikipedia.org/wiki/Memoization).

> **Link to documentation for `createSelector(_:transformation:memoized:)`.**

### Using a selector for one piece of state

```swift
import ReCombine

struct CounterState: Equatable {
    var count: Int = 0
}

struct AppState: Equatable {
    var counter: CounterState = CounterState()
}

let selectCounter = { (state: AppState) in state.counter }
let selectCount = createSelector(
    selectCounter,
    transformation: { counter in counter.count }
)
```

### Using selectors for multiple pieces of state

The `createSelector` can be used to select some data from the state based on several slices of the same state.

The `createSelector` function can take up to 9 selector functions for more complete state selections.

For example, imagine you have a `selectedUser` object in the state. You also have an `allBooks` array of book objects.

And you want to show all books for the current user.

You can use `createSelector` to achieve just that. Your visible books will always be up to date even if you update them in `allBooks`. They will always show the books that belong to your user if there is one selected and will show all the books when there is no user selected.

The result will be just some of your state filtered by another section of the state. And it will be always up to date.

```swift
import ReCombine

struct User: Equatable {
    let id: Int
    let name: String
}

struct Book: Equatable {
    let id: Int
    let userId: Int
    let name: String
}

struct AppState: Equatable {
    var selectedUser: User?
    var allBooks: [Book] = []
}

let selectUser = { (state: AppState) in state.selectedUser }
let selectAllBooks = { (state: AppState) in state.allBooks }

let selectVisibleBooks = createSelector(
    selectUser,
    selectAllBooks,
    transformation: { (selectedUser, allBooks) -> [Book] in
        if let selectedUser = selectedUser {
            return allBooks.filter { (book: Book) in book.userId == selectedUser.id }
        } else {
            return allBooks
        }
    }
)
```

## Non-Memoized Selectors

A selector's memoized value stays in memory indefinitely. If the you do not want to store the memoized value, you can use `createSelector` with `memoized: false`:

```swift
import ReCombine

let selectVisibleBooks = createSelector(
    selectUser,
    selectAllBooks,
    transformation: { (selectedUser, allBooks) -> [Book] in
        if let selectedUser = selectedUser {
            return allBooks.filter { (book: Book) in book.userId == selectedUser.id }
        } else {
            return allBooks
        }
    },
    memoized: false
)
```

## Advanced Usage

Selectors empower you to compose a [read model for your application state](https://docs.microsoft.com/en-us/azure/architecture/patterns/cqrs#solution).
In terms of the CQRS architectural pattern, ReCombine separates the read model (selectors) from the write model (reducers).

This section covers some basics of how selectors compare to pipeable operators and demonstrates how `createSelector` and `scan` are utilized to display a history of state transitions.

### Breaking Down the Basics

#### Select a non-empty state using pipeable operators

Let's pretend we have a selector called `selectValues` and the view model for displaying the data is only interested in defined values, i.e., it should not display empty states.

We can achieve this behaviour by using only Combine operators:

```swift
store
    .map({ state in selectValues(state) })
    .compactMap({ values in values })
    .sink(/* .. */)
```

The above can be further rewritten to use the `select()` utility function from ReCombine:

```swift
store
    .select(selectValues)
    .compactMap({ values in values })
    .sink(/* .. */)
```

#### Solution: Extracting a `Publisher` operator

To make the `select()` and `compactMap()` behaviour a reusable piece of code, we extract a new `Publisher` operator, specifically for `Store` where the generic state `S` matches our `AppState`:

```swift
import ReCombine

extension Store where S == AppState {
    func selectFilteredValues() -> AnyPublisher<[String], Never> {
        return select(selectValues).compactMap({ values in values }).eraseToAnyPublisher()
    }
}
store
    .selectFilteredValues()
    .sink(/* .. */)
```

### Advanced Example: Select the last {n} state transitions

Let's examine the technique of combining ReCombine selectors and Combine operators in an advanced example.

In this example, we will write a selector function that projects values from two different slices of the application state.
The projected state will emit a value when both slices of state have a value.
Otherwise, the selector will emit a `nil` value.

```swift
import ReCombine

let selectProjectedValues = createSelector(
    selectFoo,
    selectBar,
    transformation: { (foo, bar) -> (Int, Int)? in
        if let foo = foo, let bar = bar {
            return (foo, bar)
        } else {
            return nil
        }
    }
)
```

Then, the View should visualize the history of state transitions.
We are not only interested in the current state but rather like to display the last `n` pieces of state.
Meaning that we will map a stream of state values (`1`, `2`, `3`) to an array of state values (`[1, 2, 3]`).

```swift
import ReCombine
 
extension Store where S == AppState {
    // The number of state transitions is given by the user
    func selectLastStateTransitions(_ count: Int) -> AnyPublisher<[ProjectedValues], Never> {
        // Thanks to `createSelector` the operator will have memoization "for free"
        return select(selectProjectedValues)
            .compactMap({ projectedValues in projectedValues })
            // Combines the last `count` state values in array
            .scan([], { (acc: [ProjectedValues], curr: ProjectedValues) in
                var allStateTransitions = acc
                allStateTransitions.append(curr)
                return Array(allStateTransitions.prefix(count))
            }).eraseToAnyPublisher()

    }
}
```

Finally, the view model will subscribe to the store, telling the number of state transitions it wishes to display:


```swift
store
    .selectLastStateTransitions(5)
    .sink(/* .. */)
```
