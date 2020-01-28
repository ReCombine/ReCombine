//
//  CreateSelector.swift
//  ReCombine
//
//  Created by Crowson, John on 12/10/19.
//  Copyright © 2019 Crowson, John.
//  Licensed under Apache License 2.0
//

// Lack of Variadic Generics :(

/// Higher order function that creates a composable, optimized selector function.  A selector function is a pure function used for obtaining slices of store state.
/// - Parameter selectorFn: Up to nine selector functions.  The result of each selector function will be used as input to the `transformation`  parameter's closure.
/// - Parameter transformation: A projector function used to derive, transform or combine data from the state slices passed to it and return this modified data as a single object - typically for direct view consumption.
/// - Parameter memoized: True by default.  If true, will cache the result from the last input. Prevents unnecessary recomputation if dependent state slices do not change.
///
/// **Example:** The following shows a composable, memoized `selectVisibleBooks` selector function.
///
/// - **Composable:** We depend on the `selectUser` and `selectAllBooks` selectors to filter only the books belonging to the selectedUser, if one exists.
///
/// - **Memoized:** By using the default `memoized = true` parameter, if the `allMovies` section slice of the state changes, the `transformation` in `selectVisibleBooks` would not recompute.
/// ```
/// struct AppState {
///     var selectedUser: User?
///     var allBooks: [Book] = []
///     var allMovies: [Movie] = []
/// }
/// let selectUser = { (state: AppState) in state.selectedUser }
/// let selectAllBooks = { (state: AppState) in state.allBooks }
///
/// let selectVisibleBooks = createSelector(
///     selectUser,
///     selectAllBooks,
///     transformation: { (selectedUser, allBooks) -> [Book] in
///         if let selectedUser = selectedUser {
///             return allBooks.filter { (book: Book) in book.userId == selectedUser.id }
///         } else {
///             return allBooks
///         }
///     }
/// )
/// ```
public func createSelector<
    S: Equatable,
    V: Equatable,
    T
    >(_ selectorFn: @escaping SelectorFn<S, V>,
      transformation: @escaping (V) -> T,
      memoized: Bool = true
) -> SelectorFn<S, T> {
    let memoizedTransformation = memoized ? memoize(transformation) : transformation
    let selector: SelectorFn<S, T> = { (state: S) in
        let selectorFnResult = selectorFn(state)
        return memoizedTransformation(selectorFnResult)
    }
    return memoized ? memoize(selector) : selector
}

/// See documentation in `createSelector(_:transformation:memoized:)`.
public func createSelector<
    S: Equatable,
    V1: Equatable,
    V2: Equatable,
    T
    >(_ selectorFn1: @escaping SelectorFn<S, V1>,
      _ selectorFn2: @escaping SelectorFn<S, V2>,
      transformation: @escaping (V1, V2) -> T,
      memoized: Bool = true
) -> SelectorFn<S, T> {
    let memoizedTransformation = memoized ? memoize(transformation) : transformation
    let selector: SelectorFn<S, T> = { (state: S) in
        let selectorFn1Result = selectorFn1(state)
        let selectorFn2Result = selectorFn2(state)
        return memoizedTransformation(selectorFn1Result, selectorFn2Result)
    }
    return memoized ? memoize(selector) : selector
}

/// See documentation in `createSelector(_:transformation:memoized:)`.
public func createSelector<
    S: Equatable,
    V1: Equatable,
    V2: Equatable,
    V3: Equatable,
    T
    >(_ selectorFn1: @escaping SelectorFn<S, V1>,
      _ selectorFn2: @escaping SelectorFn<S, V2>,
      _ selectorFn3: @escaping SelectorFn<S, V3>,
      transformation: @escaping (V1, V2, V3) -> T,
      memoized: Bool = true
) -> SelectorFn<S, T> {
    let memoizedTransformation = memoized ? memoize(transformation) : transformation
    let selector: SelectorFn<S, T> = { (state: S) in
        let selectorFn1Result = selectorFn1(state)
        let selectorFn2Result = selectorFn2(state)
        let selectorFn3Result = selectorFn3(state)
        return memoizedTransformation(selectorFn1Result, selectorFn2Result, selectorFn3Result)
    }
    return memoized ? memoize(selector) : selector
}

/// See documentation in `createSelector(_:transformation:memoized:)`.
public func createSelector<
    S: Equatable,
    V1: Equatable,
    V2: Equatable,
    V3: Equatable,
    V4: Equatable,
    T
    >(_ selectorFn1: @escaping SelectorFn<S, V1>,
      _ selectorFn2: @escaping SelectorFn<S, V2>,
      _ selectorFn3: @escaping SelectorFn<S, V3>,
      _ selectorFn4: @escaping SelectorFn<S, V4>,
      transformation: @escaping (V1, V2, V3, V4) -> T,
      memoized: Bool = true
) -> SelectorFn<S, T> {
    let memoizedTransformation = memoized ? memoize(transformation) : transformation
    let selector: SelectorFn<S, T> = { (state: S) in
        let selectorFn1Result = selectorFn1(state)
        let selectorFn2Result = selectorFn2(state)
        let selectorFn3Result = selectorFn3(state)
        let selectorFn4Result = selectorFn4(state)
        return memoizedTransformation(selectorFn1Result, selectorFn2Result, selectorFn3Result, selectorFn4Result)
    }
    return memoized ? memoize(selector) : selector
}

/// See documentation in `createSelector(_:transformation:memoized:)`.
public func createSelector<
    S: Equatable,
    V1: Equatable,
    V2: Equatable,
    V3: Equatable,
    V4: Equatable,
    V5: Equatable,
    T
    >(_ selectorFn1: @escaping SelectorFn<S, V1>,
      _ selectorFn2: @escaping SelectorFn<S, V2>,
      _ selectorFn3: @escaping SelectorFn<S, V3>,
      _ selectorFn4: @escaping SelectorFn<S, V4>,
      _ selectorFn5: @escaping SelectorFn<S, V5>,
      transformation: @escaping (V1, V2, V3, V4, V5) -> T,
      memoized: Bool = true
) -> SelectorFn<S, T> {
    let memoizedTransformation = memoized ? memoize(transformation) : transformation
    let selector: SelectorFn<S, T> = { (state: S) in
        let selectorFn1Result = selectorFn1(state)
        let selectorFn2Result = selectorFn2(state)
        let selectorFn3Result = selectorFn3(state)
        let selectorFn4Result = selectorFn4(state)
        let selectorFn5Result = selectorFn5(state)
        return memoizedTransformation(selectorFn1Result, selectorFn2Result, selectorFn3Result, selectorFn4Result, selectorFn5Result)
    }
    return memoized ? memoize(selector) : selector
}

/// See documentation in `createSelector(_:transformation:memoized:)`.
public func createSelector<
    S: Equatable,
    V1: Equatable,
    V2: Equatable,
    V3: Equatable,
    V4: Equatable,
    V5: Equatable,
    V6: Equatable,
    T
    >(_ selectorFn1: @escaping SelectorFn<S, V1>,
      _ selectorFn2: @escaping SelectorFn<S, V2>,
      _ selectorFn3: @escaping SelectorFn<S, V3>,
      _ selectorFn4: @escaping SelectorFn<S, V4>,
      _ selectorFn5: @escaping SelectorFn<S, V5>,
      _ selectorFn6: @escaping SelectorFn<S, V6>,
      transformation: @escaping (V1, V2, V3, V4, V5, V6) -> T,
      memoized: Bool = true
) -> SelectorFn<S, T> {
    let memoizedTransformation = memoized ? memoize(transformation) : transformation
    let selector: SelectorFn<S, T> = { (state: S) in
        let selectorFn1Result = selectorFn1(state)
        let selectorFn2Result = selectorFn2(state)
        let selectorFn3Result = selectorFn3(state)
        let selectorFn4Result = selectorFn4(state)
        let selectorFn5Result = selectorFn5(state)
        let selectorFn6Result = selectorFn6(state)
        return memoizedTransformation(selectorFn1Result, selectorFn2Result, selectorFn3Result, selectorFn4Result, selectorFn5Result, selectorFn6Result)
    }
    return memoized ? memoize(selector) : selector
}

/// See documentation in `createSelector(_:transformation:memoized:)`.
public func createSelector<
    S: Equatable,
    V1: Equatable,
    V2: Equatable,
    V3: Equatable,
    V4: Equatable,
    V5: Equatable,
    V6: Equatable,
    V7: Equatable,
    T
    >(_ selectorFn1: @escaping SelectorFn<S, V1>,
      _ selectorFn2: @escaping SelectorFn<S, V2>,
      _ selectorFn3: @escaping SelectorFn<S, V3>,
      _ selectorFn4: @escaping SelectorFn<S, V4>,
      _ selectorFn5: @escaping SelectorFn<S, V5>,
      _ selectorFn6: @escaping SelectorFn<S, V6>,
      _ selectorFn7: @escaping SelectorFn<S, V7>,
      transformation: @escaping (V1, V2, V3, V4, V5, V6, V7) -> T,
      memoized: Bool = true
) -> SelectorFn<S, T> {
    let memoizedTransformation = memoized ? memoize(transformation) : transformation
    let selector: SelectorFn<S, T> = { (state: S) in
        let selectorFn1Result = selectorFn1(state)
        let selectorFn2Result = selectorFn2(state)
        let selectorFn3Result = selectorFn3(state)
        let selectorFn4Result = selectorFn4(state)
        let selectorFn5Result = selectorFn5(state)
        let selectorFn6Result = selectorFn6(state)
        let selectorFn7Result = selectorFn7(state)
        return memoizedTransformation(selectorFn1Result, selectorFn2Result, selectorFn3Result, selectorFn4Result, selectorFn5Result, selectorFn6Result, selectorFn7Result)
    }
    return memoized ? memoize(selector) : selector
}

/// See documentation in `createSelector(_:transformation:memoized:)`.
public func createSelector<
    S: Equatable,
    V1: Equatable,
    V2: Equatable,
    V3: Equatable,
    V4: Equatable,
    V5: Equatable,
    V6: Equatable,
    V7: Equatable,
    V8: Equatable,
    T
    >(_ selectorFn1: @escaping SelectorFn<S, V1>,
      _ selectorFn2: @escaping SelectorFn<S, V2>,
      _ selectorFn3: @escaping SelectorFn<S, V3>,
      _ selectorFn4: @escaping SelectorFn<S, V4>,
      _ selectorFn5: @escaping SelectorFn<S, V5>,
      _ selectorFn6: @escaping SelectorFn<S, V6>,
      _ selectorFn7: @escaping SelectorFn<S, V7>,
      _ selectorFn8: @escaping SelectorFn<S, V8>,
      transformation: @escaping (V1, V2, V3, V4, V5, V6, V7, V8) -> T,
      memoized: Bool = true
) -> SelectorFn<S, T> {
    let memoizedTransformation = memoized ? memoize(transformation) : transformation
    let selector: SelectorFn<S, T> = { (state: S) in
        let selectorFn1Result = selectorFn1(state)
        let selectorFn2Result = selectorFn2(state)
        let selectorFn3Result = selectorFn3(state)
        let selectorFn4Result = selectorFn4(state)
        let selectorFn5Result = selectorFn5(state)
        let selectorFn6Result = selectorFn6(state)
        let selectorFn7Result = selectorFn7(state)
        let selectorFn8Result = selectorFn8(state)
        return memoizedTransformation(selectorFn1Result, selectorFn2Result, selectorFn3Result, selectorFn4Result, selectorFn5Result, selectorFn6Result, selectorFn7Result, selectorFn8Result)
    }
    return memoized ? memoize(selector) : selector
}

/// See documentation in `createSelector(_:transformation:memoized:)`.
public func createSelector<
    S: Equatable,
    V1: Equatable,
    V2: Equatable,
    V3: Equatable,
    V4: Equatable,
    V5: Equatable,
    V6: Equatable,
    V7: Equatable,
    V8: Equatable,
    V9: Equatable,
    T
    >(_ selectorFn1: @escaping SelectorFn<S, V1>,
      _ selectorFn2: @escaping SelectorFn<S, V2>,
      _ selectorFn3: @escaping SelectorFn<S, V3>,
      _ selectorFn4: @escaping SelectorFn<S, V4>,
      _ selectorFn5: @escaping SelectorFn<S, V5>,
      _ selectorFn6: @escaping SelectorFn<S, V6>,
      _ selectorFn7: @escaping SelectorFn<S, V7>,
      _ selectorFn8: @escaping SelectorFn<S, V8>,
      _ selectorFn9: @escaping SelectorFn<S, V9>,
      transformation: @escaping (V1, V2, V3, V4, V5, V6, V7, V8, V9) -> T,
      memoized: Bool = true
) -> SelectorFn<S, T> {
    let memoizedTransformation = memoized ? memoize(transformation) : transformation
    let selector: SelectorFn<S, T> = { (state: S) in
        let selectorFn1Result = selectorFn1(state)
        let selectorFn2Result = selectorFn2(state)
        let selectorFn3Result = selectorFn3(state)
        let selectorFn4Result = selectorFn4(state)
        let selectorFn5Result = selectorFn5(state)
        let selectorFn6Result = selectorFn6(state)
        let selectorFn7Result = selectorFn7(state)
        let selectorFn8Result = selectorFn8(state)
        let selectorFn9Result = selectorFn9(state)
        return memoizedTransformation(selectorFn1Result, selectorFn2Result, selectorFn3Result, selectorFn4Result, selectorFn5Result, selectorFn6Result, selectorFn7Result, selectorFn8Result, selectorFn9Result)
    }
    return memoized ? memoize(selector) : selector
}

fileprivate func memoize<V: Equatable, T>(_ function: @escaping (V) -> T) -> (V) -> T {
    var lastInput: V?
    var lastOutput: T?
    return { input in
        if lastInput == input,
            let lastOutput = lastOutput {
            return lastOutput
        } else {
            let output = function(input)
            lastOutput = output
            lastInput = input
            return output
        }
    }
}

fileprivate func memoize<V1: Equatable, V2: Equatable, T>(_ function: @escaping (V1, V2) -> T) -> (V1, V2) -> T {
    var lastInput1: V1?
    var lastInput2: V2?
    var lastOutput: T?
    return { input1, input2 in
        if lastInput1 == input1,
            lastInput2 == input2,
            let lastOutput = lastOutput {
            return lastOutput
        } else {
            let output = function(input1, input2)
            lastOutput = output
            lastInput1 = input1
            lastInput2 = input2
            return output
        }
    }
}

fileprivate func memoize<V1: Equatable, V2: Equatable, V3: Equatable, T>(_ function: @escaping (V1, V2, V3) -> T) -> (V1, V2, V3) -> T {
    var lastInput1: V1?
    var lastInput2: V2?
    var lastInput3: V3?
    var lastOutput: T?
    return { input1, input2, input3 in
        if lastInput1 == input1,
            lastInput2 == input2,
            lastInput3 == input3,
            let lastOutput = lastOutput {
            return lastOutput
        } else {
            let output = function(input1, input2, input3)
            lastOutput = output
            lastInput1 = input1
            lastInput2 = input2
            lastInput3 = input3
            return output
        }
    }
}

fileprivate func memoize<V1: Equatable, V2: Equatable, V3: Equatable, V4: Equatable, T>(_ function: @escaping (V1, V2, V3, V4) -> T) -> (V1, V2, V3, V4) -> T {
    var lastInput1: V1?
    var lastInput2: V2?
    var lastInput3: V3?
    var lastInput4: V4?
    var lastOutput: T?
    return { input1, input2, input3, input4 in
        if lastInput1 == input1,
            lastInput2 == input2,
            lastInput3 == input3,
            lastInput4 == input4,
            let lastOutput = lastOutput {
            return lastOutput
        } else {
            let output = function(input1, input2, input3, input4)
            lastOutput = output
            lastInput1 = input1
            lastInput2 = input2
            lastInput3 = input3
            lastInput4 = input4
            return output
        }
    }
}

fileprivate func memoize<V1: Equatable, V2: Equatable, V3: Equatable, V4: Equatable, V5: Equatable, T>(_ function: @escaping (V1, V2, V3, V4, V5) -> T) -> (V1, V2, V3, V4, V5) -> T {
    var lastInput1: V1?
    var lastInput2: V2?
    var lastInput3: V3?
    var lastInput4: V4?
    var lastInput5: V5?
    var lastOutput: T?
    return { input1, input2, input3, input4, input5 in
        if lastInput1 == input1,
            lastInput2 == input2,
            lastInput3 == input3,
            lastInput4 == input4,
            lastInput5 == input5,
            let lastOutput = lastOutput {
            return lastOutput
        } else {
            let output = function(input1, input2, input3, input4, input5)
            lastOutput = output
            lastInput1 = input1
            lastInput2 = input2
            lastInput3 = input3
            lastInput4 = input4
            lastInput5 = input5
            return output
        }
    }
}

fileprivate func memoize<V1: Equatable, V2: Equatable, V3: Equatable, V4: Equatable, V5: Equatable, V6: Equatable, T>(_ function: @escaping (V1, V2, V3, V4, V5, V6) -> T) -> (V1, V2, V3, V4, V5, V6) -> T {
    var lastInput1: V1?
    var lastInput2: V2?
    var lastInput3: V3?
    var lastInput4: V4?
    var lastInput5: V5?
    var lastInput6: V6?
    var lastOutput: T?
    return { input1, input2, input3, input4, input5, input6 in
        if lastInput1 == input1,
            lastInput2 == input2,
            lastInput3 == input3,
            lastInput4 == input4,
            lastInput5 == input5,
            lastInput6 == input6,
            let lastOutput = lastOutput {
            return lastOutput
        } else {
            let output = function(input1, input2, input3, input4, input5, input6)
            lastOutput = output
            lastInput1 = input1
            lastInput2 = input2
            lastInput3 = input3
            lastInput4 = input4
            lastInput5 = input5
            lastInput6 = input6
            return output
        }
    }
}

fileprivate func memoize<V1: Equatable, V2: Equatable, V3: Equatable, V4: Equatable, V5: Equatable, V6: Equatable, V7: Equatable, T>(_ function: @escaping (V1, V2, V3, V4, V5, V6, V7) -> T) -> (V1, V2, V3, V4, V5, V6, V7) -> T {
    var lastInput1: V1?
    var lastInput2: V2?
    var lastInput3: V3?
    var lastInput4: V4?
    var lastInput5: V5?
    var lastInput6: V6?
    var lastInput7: V7?
    var lastOutput: T?
    return { input1, input2, input3, input4, input5, input6, input7 in
        if lastInput1 == input1,
            lastInput2 == input2,
            lastInput3 == input3,
            lastInput4 == input4,
            lastInput5 == input5,
            lastInput6 == input6,
            lastInput7 == input7,
            let lastOutput = lastOutput {
            return lastOutput
        } else {
            let output = function(input1, input2, input3, input4, input5, input6, input7)
            lastOutput = output
            lastInput1 = input1
            lastInput2 = input2
            lastInput3 = input3
            lastInput4 = input4
            lastInput5 = input5
            lastInput6 = input6
            lastInput7 = input7
            return output
        }
    }
}

fileprivate func memoize<V1: Equatable, V2: Equatable, V3: Equatable, V4: Equatable, V5: Equatable, V6: Equatable, V7: Equatable, V8: Equatable, T>(_ function: @escaping (V1, V2, V3, V4, V5, V6, V7, V8) -> T) -> (V1, V2, V3, V4, V5, V6, V7, V8) -> T {
    var lastInput1: V1?
    var lastInput2: V2?
    var lastInput3: V3?
    var lastInput4: V4?
    var lastInput5: V5?
    var lastInput6: V6?
    var lastInput7: V7?
    var lastInput8: V8?
    var lastOutput: T?
    return { input1, input2, input3, input4, input5, input6, input7, input8 in
        if lastInput1 == input1,
            lastInput2 == input2,
            lastInput3 == input3,
            lastInput4 == input4,
            lastInput5 == input5,
            lastInput6 == input6,
            lastInput7 == input7,
            lastInput8 == input8,
            let lastOutput = lastOutput {
            return lastOutput
        } else {
            let output = function(input1, input2, input3, input4, input5, input6, input7, input8)
            lastOutput = output
            lastInput1 = input1
            lastInput2 = input2
            lastInput3 = input3
            lastInput4 = input4
            lastInput5 = input5
            lastInput6 = input6
            lastInput7 = input7
            lastInput8 = input8
            return output
        }
    }
}

fileprivate func memoize<V1: Equatable, V2: Equatable, V3: Equatable, V4: Equatable, V5: Equatable, V6: Equatable, V7: Equatable, V8: Equatable, V9: Equatable, T>(_ function: @escaping (V1, V2, V3, V4, V5, V6, V7, V8, V9) -> T) -> (V1, V2, V3, V4, V5, V6, V7, V8, V9) -> T {
    var lastInput1: V1?
    var lastInput2: V2?
    var lastInput3: V3?
    var lastInput4: V4?
    var lastInput5: V5?
    var lastInput6: V6?
    var lastInput7: V7?
    var lastInput8: V8?
    var lastInput9: V9?
    var lastOutput: T?
    return { input1, input2, input3, input4, input5, input6, input7, input8, input9 in
        if lastInput1 == input1,
            lastInput2 == input2,
            lastInput3 == input3,
            lastInput4 == input4,
            lastInput5 == input5,
            lastInput6 == input6,
            lastInput7 == input7,
            lastInput8 == input8,
            lastInput9 == input9,
            let lastOutput = lastOutput {
            return lastOutput
        } else {
            let output = function(input1, input2, input3, input4, input5, input6, input7, input8, input9)
            lastOutput = output
            lastInput1 = input1
            lastInput2 = input2
            lastInput3 = input3
            lastInput4 = input4
            lastInput5 = input5
            lastInput6 = input6
            lastInput7 = input7
            lastInput8 = input8
            lastInput9 = input9
            return output
        }
    }
}
