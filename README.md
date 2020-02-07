<img alt="ReCombine Logo" width="400px" style="padding-top:16px" src="https://user-images.githubusercontent.com/2394173/73595166-56a2db80-44e3-11ea-817e-86df1dd03555.png">

**Simple. Performant. Native.**

![Swift](https://github.com/ReCombine/ReCombine/workflows/Swift/badge.svg?branch=master)
![Platform support](https://img.shields.io/badge/platform-ios%20%7C%20osx%20%7C%20tvos%20%7C%20watchos-lightgrey.svg?style=flat-square)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/ReCombine/ReCombine/blob/master/LICENSE)

A Swift Redux Library utilizing Apple's Combine Framework.

## Documentation

See the full documentation on [ReCombine.io](https://recombine.io)

## Why ReCombine?

- **Simple**
   - 📈 [Combine reducers](https://recombine.io/Reducer%20Composition%20Helpers.html#/s:9ReCombine15combineReducersyxx_AA6Action_ptcxx_AaC_ptcd_tlF) makes scaling easy.
   - 🤝 [Side Effects](https://recombine.io/effects.html) allow abstraction of asynchronous calls. 
- **Performant** 
   - 🚀 Uses Combine, boosting performance in comparison to Redux libraries that use RxSwift.
   - 🦁 Implements performance optimizations for you, including [memoized selectors](https://recombine.io/selectors.html).
- **Native** 
   - 📲 Interacts seemlessly with SwiftUI.
   - 🛠 Only depends on Combine under the hood.

## Inspiration

The API is inspired by [NgRx](https://ngrx.io/), Angular's most popular Redux framework.
