# What is ReCombine?

ReCombine is a Combine powered state management for iOS, macOS, watchOS, and tvOS applications, inspired by Redux and [NgRx](https://ngrx.io). ReCombine is a controlled state container designed to help write performant, consistent iOS applications.  ReCombine also provides isolation of side effects.

## Why ReCombine for State Management?

ReCombine provides state management for creating maintainable explicit applications, by storing single state and the use of actions in order to express state changes.

### Encapsulation

Using ReCombine [Effects](./effects.html) and `Store`, any interaction with external resources, like network requests, web socket and any business logic can be isolated from the UI. This isolation allows for more pure and simple views, and keep the single responsibility principle.

### Performance

ReCombine is powered Combine, leading to better performance than Redux libraries that use RxSwift.  Features like memoized selector functions optimize state query computations.

### Native

In addition to the performance benefits of a Combine-based library, many developers prefer to write code that interacts with Apple's core libraries.  These solutions lead to simpler interactions with other Apple libraries, including SwiftUI.

## When Should I Use ReCombine for State Management

In particular, you might use ReCombine when you build an application with a lot of user interactions and multiple data sources, when managing state in singletons or passed objects are no longer sufficient.

You may need ReCombine if your state is:

* **Shared**: state that is accessed by many views and view models.

* **Retrieved**: state that must be retrieved with a side-effect.

* **Impacted**: state that is impacted by actions from other sources.

## When Should I Not Use ReCombine for State Management

It is important to note that ReCombine depends on Combine, so ReCombine supports applications that are iOS 13+.
