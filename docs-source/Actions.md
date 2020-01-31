# Actions

Actions are one of the main building blocks in ReCombine. Actions express _unique events_ that happen throughout your application. From user interaction with the page, external interaction through network requests, and direct interaction with device APIs, these and more events are described with actions.

## Introduction

Actions are used in many areas of ReCombine. Actions are the inputs and outputs of many systems in ReCombine. Actions help you to understand how events are handled in your application. This guide provides general rules and examples for writing actions in your application.

## The Action protocol

An `Action` in ReCombine is made up of a simple protocol:

```swift
public protocol Action {}
```

The protocol should be implemented with a name describing the action that will be dispatched in your application. Actions can be nested inside other structures to group categories of actions based on event source. You add properties to an action to provide additional context or metadata for an action.

Listed below are examples of actions:

```swift
import ReCombine

struct AuthenticationLoginSuccess: Action {}
```

It can be helpful to group similar actions by category as well:

```swift
import ReCombine

enum Counter {
    struct Increment: Action {}
    struct Decrement: Action {}
    // other counter actions...
}
```

These actions describe events triggered by a user clicking on the increment and decrement buttons on the UI.

```swift
import ReCombine

enum Authentication {
    struct Login: Action {
        let username: String
        let password: String
    }
}
```

This action describes an event triggered by a user clicking a login button from the authentication page to attempt to authenticate a user. The username and password are defined as additional metadata provided from the authentication view controller.

## Writing actions

There are a few rules to writing good actions within your application.

- **Upfront** - write actions before developing features to understand and gain a shared knowledge of the feature being implemented.
- **Divide** - categorize actions based on the event source.
- **Many** - actions are inexpensive to write, so the more actions you write, the better you express flows in your application.
- **Event-Driven** - capture _events_ **not** _commands_ as you are separating the description of an event and the handling of that event.
- **Descriptive** - provide context that are targeted to a unique event with more detailed information you can use to aid in debugging.

Following these guidelines helps you follow how these actions flow throughout your application.

Let's look at an example action of initiating a login request.

```swift
import ReCombine

enum Authentication {
    struct Login: Action {
        let username: String
        let password: String
    }
}
```

Use the action when dispatching.

```swift
@IBAction func test(_ sender: UIButton) {
    store.dispatch(action: Authentication.Login(username: getUsername(), password: getPassword()))
}
```

The action has very specific context about where the action came from and what event happened.

## Next Steps

Action's only responsibilities are to express unique events and intents. Learn how they are handled in the guides below.

- [Reducers](./reducers.html)
- [Effects](./effects.html)
