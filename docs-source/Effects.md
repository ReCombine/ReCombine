# Effects

Effects are a Combine powered side effect model. Effects use streams to provide [new sources](https://martinfowler.com/eaaDev/EventSourcing.html) of actions to reduce state based on external interactions such as network requests, web socket messages and time-based events.

## Introduction

In many iOS applications, view controllers or their dependencies (view models, data managers) are responsible for interacting with external resources directly. Instead, effects provide a way to interact with those resources and isolate them from the view controllers.

Effects are where you handle tasks such as fetching data, long-running tasks that produce multiple events, and other external interactions where your view controllers don't need explicit knowledge of these interactions.

## Key Concepts

- Effects isolate side effects from view controllers or view models, allowing for more _pure_ view controllers or view models that select state and dispatch actions.
- Effects are long-running Subscribers that listen to a Publisher of _every_ action dispatched from the [Store](guide/store).
- Effects filter those actions based on the type of action they are interested in.
- Effects perform tasks, which are synchronous or asynchronous and return a new action.

## Comparison with UIViewController-based side effects

In many iOS applications, your view controllers or it's dependencies interact with data directly.

Imagine that your application manages message board posts. Here is a view controller that fetches and displays a single post.

```swift
import UIKit

class PostDetailsViewController: UIViewController {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var bodyLabel: UILabel!

    var postId: String = "1"  // Pass from another view

    override func viewDidLoad() {
        super.viewDidLoad()
        let session = URLSession(configuration: .default, delegate: ServerTrustDelegate(), delegateQueue: .main)
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/\(postId)")!
        let task = session.dataTask(with: url, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            guard let data = data, let post = try? JSONDecoder().decode(Post.self, from: data) else {
                return
            }
            self.titleLabel.text = post.title
            self.bodyLabel.text = post.body
        })
        task.resume()
    }
}
```

The view controller has multiple responsibilities:

- Maintaining the _state_/outlets for the post.
- Using the `URLSession` to perform a _side effect_, reaching out to an external API to fetch the post.
- Changing the _state_/outlets after the API is complete.

`Effects` when used along with `Store`, decrease the responsibility of view controllers and it's dependencies.  In a larger application, this becomes more important because you have multiple sources of data, with possibly multiple dependencies required to fetch those pieces of data.

Effects handle external data and interactions, allowing your view controllers to be less stateful and only perform tasks related to external interactions. Next, refactor the view controller to put the post detail data in the `Store`. Effects handle the fetching of post data.

```swift
import UIKit
import Combine

class PostDetailsViewController: UIViewController {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var bodyLabel: UILabel!

    var postId: String = "1"  // Pass from another view
    private var cancellableSet: Set<AnyCancellable> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        store.dispatch(action: PostDetailsView.GetPost(id: postId))
        store.select(selectPostDetailsTitle)
            .assign(to: \.text, on: titleLabel)
            .store(in: &cancellableSet)
        store.select(selectPostDetailsBody)
            .assign(to: \.text, on: bodyLabel)
            .store(in: &cancellableSet)
    }
}
```

The post is still fetched through the `URLSession`, but the view controller is no longer concerned with how the post is fetched and loaded. It's only responsible for declaring its _intent_ to load the post and using selectors to access post data. Effects are where the asynchronous activity of fetching a post happens. Your view controller becomes easier to test and less responsible for the data it needs.

## Writing Effects

To isolate side-effects from your view controller and it's dependencies, you must create an `Effect` to listen for events and perform tasks.

Effects are structs with distinct parts:

- A closure that receives an  `Action` parameter for _all_ actions dispatched _after_ the latest state has been reduced.  The closure must return a `Publisher<Action, Never>`.
- By default, any action returned from the closure Publisher is then dispatched back to the `Store`.  This can be configured using the `Effect` `dispatch` property. 
- Actions can be filtered using the `ofType(_:)` or `ofTypes(_:_:)` operators. The `ofType(_:)` operator takes a single action type as an argument to filter on which actions to act upon.  The `ofTypes(_:_:)` operator can take up to five action types, but will return a generic `Action` instead of a specific `Action` implementation.

To show how you handle loading a post from the example above, let's look at `PostDetailsView.getPostEffect`.

```swift
static let getPostEffect = Effect(dispatch: true) { actions in
    actions
        .ofType(GetPost.self)
        .flatMap(getPostAPI)
        .eraseToAnyPublisher()
}

static func getPostAPI(action: GetPost) -> AnyPublisher<Action, Never> {
    guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts/\(action.id)") else {
        return Just(GetPostError()).eraseToAnyPublisher()
    }
    let session = URLSession(configuration: .default, delegate: ServerTrustDelegate(), delegateQueue: .main)
    return session.dataTaskPublisher(for: url)
        .map { $0.data }
        .decode(type: Post.self, decoder: JSONDecoder())
        .map({ post in GetPostSuccess(post: post) })
        .replaceError(with: GetPostError())
        .eraseToAnyPublisher()
}
```

The `getPostEffect` is listening for all dispatched actions through the `actions` stream, but is only interested in the `GetPost` event using the `ofType(_:)` operator. The stream of actions is then flattened and mapped into a new Publisher using the `flatMap` operator. The `getPostAPI` function returns a Publisher that maps the post to a new success action on success, and if an error occurs, maps to a new error action. The action is dispatched to the `Store` where it can be handled by reducers when a state change is needed. Its also important to handle errors when dealing with Publisher streams so that the effects continue running.

Also note that effects have access to properties of the action, as shown above when calling the API endpoint with `action.id`.

## Non-dispatching Effects

Sometimes you don't want effects to dispatch an action, for example when you only want to log or navigate based on an incoming action. But when an effect does not map to a different type of action, the application will crash because the effect is both listening to and dispatching the exact same action over and over again, causing an infinite loop. To prevent this, use `dispatch: false` in the `Effect` initializer.

```swift
static let deleteEffect = Effect(dispatch: false) { actions in
    actions
        .ofType(DeleteDocument.self)
        .handleEvents(receiveOutput: { action in print("Document \(action.id) deleted.") })
        .eraseActionType()
        .eraseToAnyPublisher()
}
```
You'll notice the specific `DeleteDocument` action had to be type erased using `eraseActionType()` to allow the closure to return a `Publisher` that satisfies the requirement that `Output == Action`.

## Registering effects

After you've written your Effects, you must register them so the effects start running. 

### Permanent global effects

To register effects that will process all actions for the entire lifecycle of the `Store` instance, add them to the `Store` initializer.

```swift
let store = Store(reducer: reducers, initialState: AppState(), effects: [PostDetailsView.getPostEffect])
```

Effects start running immediately to ensure they are listening for all relevant actions.

### Temporary local effects

To register effects that will process for a specific lifetime and can access local scopes, use the `register(_:)` method.  See the function-level documentation for details.
```swift
let showAlertOnError = Effect(dispatch: false) { actions in
    actions.ofType(GetPostError.self)
        .handleEvents(receiveOutput: { [weak self] _ in
            self?.showAlert = true
        })
        .eraseActionType()
        .eraseToAnyPublisher()
}
store.register(showAlertOnError)
```
## Advanced: More than five action types

As mentioned, `ofTypes(_:_:)` supports up to five action types.  To whitelist more than the five action types, combine multiple `ofTypes` operators together using `Publishers.Merge()`:
```swift
let actionsWhitelist = Publishers.Merge(
    actions.ofTypes(Action1.self, Action2.self, Action3.self, Action4.self, Action5.self), 
    actions.ofTypes(Action6.self, Action7.self, Action8.self)
)
```
