import Combine
import XCTest
@testable import ReCombine

final class ReCombineTests: XCTestCase {
    
    // Store, Reducer setup
    
    struct ScoreboardState: Equatable {
        var home = Home.State()
        var away = Away.State()
        var lastActionIsAction2 = false
    }
    
    struct ResetScore: Action {}
    
    enum Home {
        struct Score: Action {}
        struct State: Equatable {
            var score = 0
        }
        static func reducer(state: State, action: Action) -> State {
            var state = state
            switch action {
                case _ as Score:
                    state.score += 1
                    return state
                case _ as ResetScore:
                    state.score = 0
                    return state
                default:
                    return state
            }
        }
    }
    
    func getHomeScore(state: ScoreboardState) -> Int {
        return state.home.score
    }
    
    enum Away {
        struct Score: Action {}
        struct State: Equatable {
            var score = 0
        }
        static func reducer(state: State, action: Action) -> State {
            var state = state
            switch action {
                case _ as Score:
                    state.score += 1
                    return state
                case _ as ResetScore:
                    state.score = 0
                    return state
                default:
                    return state
            }
        }
    }
    
    static func lastActionIsAction2Reducer(state: Bool, action: Action) -> Bool {
        return action is Action2
    }
    
    static let reducer: ReducerFn<ScoreboardState> = combineReducers(
        forKey(\.home, use: Home.reducer),
        forKey(\.away, use: Away.reducer),
        forKey(\.lastActionIsAction2, use: lastActionIsAction2Reducer)
    )
    
    // Effects setup
    
    struct Action1: Action {}
    struct Action2: Action {}
    struct Action3: Action {}
    struct Action4: Action {}
    struct Action5: Action {}
    struct Action6: Action {}
    
    static let doesDispatch = Effect(dispatch: true) { action in
        action.ofType(Action1.self)
            .map { _ in Action2() }
            .eraseActionType()
            .eraseToAnyPublisher()
    }
    
    static let doesNotDispatch = Effect(dispatch: false) { action in
        action.ofType(Action2.self)
            .map { _ in ResetScore() }
            .eraseActionType()
            .eraseToAnyPublisher()
    }
    
    static let registerThisLater = Effect(dispatch: true) { action in
        action.ofType(Home.Score.self)
            .map { _ in Away.Score() }
            .eraseActionType()
            .eraseToAnyPublisher()
    }

    var store = Store(reducer: ReCombineTests.reducer, initialState: ScoreboardState(), effects: [ReCombineTests.doesDispatch, ReCombineTests.doesNotDispatch])
    
    var cancellable: AnyCancellable?
    var cancellableSet: Set<AnyCancellable> = []
    
    override func setUp() {
        store = Store(reducer: ReCombineTests.reducer, initialState: ScoreboardState(), effects: [ReCombineTests.doesDispatch, ReCombineTests.doesNotDispatch])
    }
    
    // MARK: - Store
    
    func testInitialState() {
        let expectationReceiveValue = expectation(description: "receiveValue")
        cancellable = store.sink(receiveValue: { state in
            XCTAssertEqual(0, state.home.score)
            XCTAssertEqual(0, state.away.score)
            expectationReceiveValue.fulfill()
        })
        
        wait(for: [expectationReceiveValue], timeout: 10)
    }
    
    // MARK: - Dispatch, combineReducers
    
    func testDispatch_HomeScore_IncrementsState() {
        let expectationReceiveValue = expectation(description: "receiveValue")
        store.dispatch(action: Home.Score())
        cancellable = store.sink(receiveValue: { state in
            XCTAssertEqual(1, state.home.score)
            XCTAssertEqual(0, state.away.score)
            expectationReceiveValue.fulfill()
        })
        
        wait(for: [expectationReceiveValue], timeout: 10)
    }
    
    func testDispatch_AwayScore_IncrementsState() {
        let expectationReceiveValue = expectation(description: "receiveValue")
        store.dispatch(action: Away.Score())
        cancellable = store.sink(receiveValue: { state in
            XCTAssertEqual(0, state.home.score)
            XCTAssertEqual(1, state.away.score)
            expectationReceiveValue.fulfill()
        })
        
        wait(for: [expectationReceiveValue], timeout: 10)
    }
    
    func testDispatch_ResetScore_ResetsState() {
        let expectationReceiveValue = expectation(description: "receiveValue")
        store.dispatch(action: Away.Score())
        store.dispatch(action: ResetScore())
        cancellable = store.sink(receiveValue: { state in
            XCTAssertEqual(0, state.home.score)
            XCTAssertEqual(0, state.away.score)
            expectationReceiveValue.fulfill()
        })
        
        wait(for: [expectationReceiveValue], timeout: 10)
    }
    
    // MARK: - Effects
    
    func testEffects_ShouldDispatch() {
        let expectationReceiveValue = expectation(description: "receiveValue")
        store.dispatch(action: Action1())
        cancellable = store.sink(receiveValue: { state in
            XCTAssertTrue(state.lastActionIsAction2)
            expectationReceiveValue.fulfill()
        })
        
        wait(for: [expectationReceiveValue], timeout: 10)
    }
    
    func testEffects_ShouldNotDispatch() {
        let expectationReceiveValue = expectation(description: "receiveValue")
        store.dispatch(action: Action2())
        cancellable = store.sink(receiveValue: { state in
            XCTAssertTrue(state.lastActionIsAction2)
            expectationReceiveValue.fulfill()
        })
        
        wait(for: [expectationReceiveValue], timeout: 10)
    }
    
    // MARK: - register(_:) Effects
    
    func testRegister_EffectShouldDispatchForLifetimeOfCancellable() {
        let expectationReceiveValueOf3 = expectation(description: "receiveValueOf3")
        let expectationReceiveValueOf4 = expectation(description: "receiveValueOf4")
        store.dispatch(action: Home.Score())
        store.dispatch(action: Home.Score())
        // Cancellable lifetime begins
        cancellable = store.register(ReCombineTests.registerThisLater)
        store.dispatch(action: Home.Score())
        store.filter { state in state.home.score == 3 }.sink(receiveValue: { [weak self] state in
            XCTAssertEqual(3, state.home.score)
            XCTAssertEqual(1, state.away.score)
            // Cancellable lifetime ends
            self?.cancellable?.cancel()
            self?.store.dispatch(action: Home.Score())
            expectationReceiveValueOf3.fulfill()
            }).store(in: &cancellableSet)
        
        store.filter { state in state.home.score == 4 }.sink(receiveValue: { state in
            XCTAssertEqual(4, state.home.score)
            XCTAssertEqual(1, state.away.score)
            expectationReceiveValueOf4.fulfill()
        }).store(in: &cancellableSet)
        
        wait(for: [expectationReceiveValueOf3, expectationReceiveValueOf4], timeout: 10)
    }
    
    // MARK: - Memoized Selectors
    
    func testCreateSelector1_ShouldEvaluateOnNewHomeScoreOnly() {
        var transformFuncExecutions = 0
        var selectorEmissions = 0

        func sumString(_ score: Int) -> String {
            transformFuncExecutions += 1
            return "Score is \(score)"
        }
        // Define selector
        let getSum = createSelector(getHomeScore, transformation: sumString)
        
        // Use selector
        store.select(getSum)
            .sink(receiveValue: {_ in selectorEmissions += 1 })
            .store(in: &cancellableSet)
        
        // Dispatch 1 home action and 4 away actions
        store.dispatch(action: Away.Score())
        store.dispatch(action: Home.Score())
        store.dispatch(action: Away.Score())
        store.dispatch(action: Away.Score())
        store.dispatch(action: Away.Score())
        
        // When away score reaches 4, assert home selector only triggered twice:
        // Once with initial store value, once when home score changed.
        let expectationReceiveValueOf4 = expectation(description: "receiveValueOf4")
        store.filter { state in state.away.score == 4 }
            .sink(receiveValue: { state in
                XCTAssertEqual(1, state.home.score)
                XCTAssertEqual(4, state.away.score)
                XCTAssertEqual(2, transformFuncExecutions)
                XCTAssertEqual(2, selectorEmissions)
                self.store.select(getSum)
                    .sink(receiveValue: { sumString in
                        XCTAssertEqual("Score is 1", sumString)
                        expectationReceiveValueOf4.fulfill()
                    }).store(in: &self.cancellableSet)
            }).store(in: &cancellableSet)
        
        wait(for: [expectationReceiveValueOf4], timeout: 10)
    }
    
    func testCreateSelector2_ShouldEvaluateOnNewHomeScoreOnly() {
        var transformFuncExecutions = 0
        var selectorEmissions = 0

        func sumString(_ score1: Int, _ score2: Int) -> String {
            transformFuncExecutions += 1
            return "Score is \(score1 + score2)"
        }
        // Define selector
        let getSum = createSelector(getHomeScore, getHomeScore, transformation: sumString)
        
        // Use selector
        store.select(getSum)
            .sink(receiveValue: {_ in selectorEmissions += 1 })
            .store(in: &cancellableSet)
        
        // Dispatch 1 home action and 4 away actions
        store.dispatch(action: Away.Score())
        store.dispatch(action: Home.Score())
        store.dispatch(action: Away.Score())
        store.dispatch(action: Away.Score())
        store.dispatch(action: Away.Score())
        
        // When away score reaches 4, assert home selector only triggered twice:
        // Once with initial store value, once when home score changed.
        let expectationReceiveValueOf4 = expectation(description: "receiveValueOf4")
        store.filter { state in state.away.score == 4 }
            .sink(receiveValue: { state in
                XCTAssertEqual(1, state.home.score)
                XCTAssertEqual(4, state.away.score)
                XCTAssertEqual(2, transformFuncExecutions)
                XCTAssertEqual(2, selectorEmissions)
                self.store.select(getSum)
                    .sink(receiveValue: { sumString in
                        XCTAssertEqual("Score is 2", sumString)
                        expectationReceiveValueOf4.fulfill()
                    }).store(in: &self.cancellableSet)
            }).store(in: &cancellableSet)
        
        wait(for: [expectationReceiveValueOf4], timeout: 10)
    }
    
    func testCreateSelector3_ShouldEvaluateOnNewHomeScoreOnly() {
        var transformFuncExecutions = 0
        var selectorEmissions = 0

        func sumString(_ score1: Int, _ score2: Int, _ score3: Int) -> String {
            transformFuncExecutions += 1
            return "Score is \(score1 + score2 + score3)"
        }
        // Define selector
        let getSum = createSelector(getHomeScore, getHomeScore, getHomeScore, transformation: sumString)
        
        // Use selector
        store.select(getSum)
            .sink(receiveValue: {_ in selectorEmissions += 1 })
            .store(in: &cancellableSet)
        
        // Dispatch 1 home action and 4 away actions
        store.dispatch(action: Away.Score())
        store.dispatch(action: Home.Score())
        store.dispatch(action: Away.Score())
        store.dispatch(action: Away.Score())
        store.dispatch(action: Away.Score())
        
        // When away score reaches 4, assert home selector only triggered twice:
        // Once with initial store value, once when home score changed.
        let expectationReceiveValueOf4 = expectation(description: "receiveValueOf4")
        store.filter { state in state.away.score == 4 }
            .sink(receiveValue: { state in
                XCTAssertEqual(1, state.home.score)
                XCTAssertEqual(4, state.away.score)
                XCTAssertEqual(2, transformFuncExecutions)
                XCTAssertEqual(2, selectorEmissions)
                self.store.select(getSum)
                    .sink(receiveValue: { sumString in
                        XCTAssertEqual("Score is 3", sumString)
                        expectationReceiveValueOf4.fulfill()
                    }).store(in: &self.cancellableSet)
            }).store(in: &cancellableSet)
        
        wait(for: [expectationReceiveValueOf4], timeout: 10)
    }
    
    func testCreateSelector4_ShouldEvaluateOnNewHomeScoreOnly() {
        var transformFuncExecutions = 0
        var selectorEmissions = 0

        func sumString(_ score1: Int, _ score2: Int, _ score3: Int, _ score4: Int) -> String {
            transformFuncExecutions += 1
            return "Score is \(score1 + score2 + score3 + score4)"
        }
        // Define selector
        let getSum = createSelector(getHomeScore, getHomeScore, getHomeScore, getHomeScore, transformation: sumString)
        
        // Use selector
        store.select(getSum)
            .sink(receiveValue: {_ in selectorEmissions += 1 })
            .store(in: &cancellableSet)
        
        // Dispatch 1 home action and 4 away actions
        store.dispatch(action: Away.Score())
        store.dispatch(action: Home.Score())
        store.dispatch(action: Away.Score())
        store.dispatch(action: Away.Score())
        store.dispatch(action: Away.Score())
        
        // When away score reaches 4, assert home selector only triggered twice:
        // Once with initial store value, once when home score changed.
        let expectationReceiveValueOf4 = expectation(description: "receiveValueOf4")
        store.filter { state in state.away.score == 4 }
            .sink(receiveValue: { state in
                XCTAssertEqual(1, state.home.score)
                XCTAssertEqual(4, state.away.score)
                XCTAssertEqual(2, transformFuncExecutions)
                XCTAssertEqual(2, selectorEmissions)
                self.store.select(getSum)
                    .sink(receiveValue: { sumString in
                        XCTAssertEqual("Score is 4", sumString)
                        expectationReceiveValueOf4.fulfill()
                    }).store(in: &self.cancellableSet)
            }).store(in: &cancellableSet)
        
        wait(for: [expectationReceiveValueOf4], timeout: 10)
    }
    
    func testCreateSelector5_ShouldEvaluateOnNewHomeScoreOnly() {
        var transformFuncExecutions = 0
        var selectorEmissions = 0

        func sumString(_ score1: Int, _ score2: Int, _ score3: Int, _ score4: Int, _ score5: Int) -> String {
            transformFuncExecutions += 1
            return "Score is \(score1 + score2 + score3 + score4 + score5)"
        }
        // Define selector
        let getSum = createSelector(getHomeScore, getHomeScore, getHomeScore, getHomeScore, getHomeScore, transformation: sumString)
        
        // Use selector
        store.select(getSum)
            .sink(receiveValue: {_ in selectorEmissions += 1 })
            .store(in: &cancellableSet)
        
        // Dispatch 1 home action and 4 away actions
        store.dispatch(action: Away.Score())
        store.dispatch(action: Home.Score())
        store.dispatch(action: Away.Score())
        store.dispatch(action: Away.Score())
        store.dispatch(action: Away.Score())
        
        // When away score reaches 4, assert home selector only triggered twice:
        // Once with initial store value, once when home score changed.
        let expectationReceiveValueOf4 = expectation(description: "receiveValueOf4")
        store.filter { state in state.away.score == 4 }
            .sink(receiveValue: { state in
                XCTAssertEqual(1, state.home.score)
                XCTAssertEqual(4, state.away.score)
                XCTAssertEqual(2, transformFuncExecutions)
                XCTAssertEqual(2, selectorEmissions)
                self.store.select(getSum)
                    .sink(receiveValue: { sumString in
                        XCTAssertEqual("Score is 5", sumString)
                        expectationReceiveValueOf4.fulfill()
                    }).store(in: &self.cancellableSet)
            }).store(in: &cancellableSet)
        
        wait(for: [expectationReceiveValueOf4], timeout: 10)
    }
    
    func testCreateSelector6_ShouldEvaluateOnNewHomeScoreOnly() {
        var transformFuncExecutions = 0
        var selectorEmissions = 0

        func sumString(_ score1: Int, _ score2: Int, _ score3: Int, _ score4: Int, _ score5: Int, _ score6: Int) -> String {
            transformFuncExecutions += 1
            return "Score is \(score1 + score2 + score3 + score4 + score5 + score6)"
        }
        // Define selector
        let getSum = createSelector(getHomeScore, getHomeScore, getHomeScore, getHomeScore, getHomeScore, getHomeScore, transformation: sumString)
        
        // Use selector
        store.select(getSum)
            .sink(receiveValue: {_ in selectorEmissions += 1 })
            .store(in: &cancellableSet)
        
        // Dispatch 1 home action and 4 away actions
        store.dispatch(action: Away.Score())
        store.dispatch(action: Home.Score())
        store.dispatch(action: Away.Score())
        store.dispatch(action: Away.Score())
        store.dispatch(action: Away.Score())
        
        // When away score reaches 4, assert home selector only triggered twice:
        // Once with initial store value, once when home score changed.
        let expectationReceiveValueOf4 = expectation(description: "receiveValueOf4")
        store.filter { state in state.away.score == 4 }
            .sink(receiveValue: { state in
                XCTAssertEqual(1, state.home.score)
                XCTAssertEqual(4, state.away.score)
                XCTAssertEqual(2, transformFuncExecutions)
                XCTAssertEqual(2, selectorEmissions)
                self.store.select(getSum)
                    .sink(receiveValue: { sumString in
                        XCTAssertEqual("Score is 6", sumString)
                        expectationReceiveValueOf4.fulfill()
                    }).store(in: &self.cancellableSet)
            }).store(in: &cancellableSet)
        
        wait(for: [expectationReceiveValueOf4], timeout: 10)
    }
    
    func testCreateSelector7_ShouldEvaluateOnNewHomeScoreOnly() {
        var transformFuncExecutions = 0
        var selectorEmissions = 0

        func sumString(_ score1: Int, _ score2: Int, _ score3: Int, _ score4: Int, _ score5: Int, _ score6: Int, _ score7: Int) -> String {
            transformFuncExecutions += 1
            return "Score is \(score1 + score2 + score3 + score4 + score5 + score6 + score7)"
        }
        // Define selector
        let getSum = createSelector(getHomeScore, getHomeScore, getHomeScore, getHomeScore, getHomeScore, getHomeScore, getHomeScore, transformation: sumString)
        
        // Use selector
        store.select(getSum)
            .sink(receiveValue: {_ in selectorEmissions += 1 })
            .store(in: &cancellableSet)
        
        // Dispatch 1 home action and 4 away actions
        store.dispatch(action: Away.Score())
        store.dispatch(action: Home.Score())
        store.dispatch(action: Away.Score())
        store.dispatch(action: Away.Score())
        store.dispatch(action: Away.Score())
        
        // When away score reaches 4, assert home selector only triggered twice:
        // Once with initial store value, once when home score changed.
        let expectationReceiveValueOf4 = expectation(description: "receiveValueOf4")
        store.filter { state in state.away.score == 4 }
            .sink(receiveValue: { state in
                XCTAssertEqual(1, state.home.score)
                XCTAssertEqual(4, state.away.score)
                XCTAssertEqual(2, transformFuncExecutions)
                XCTAssertEqual(2, selectorEmissions)
                self.store.select(getSum)
                    .sink(receiveValue: { sumString in
                        XCTAssertEqual("Score is 7", sumString)
                        expectationReceiveValueOf4.fulfill()
                    }).store(in: &self.cancellableSet)
            }).store(in: &cancellableSet)
        
        wait(for: [expectationReceiveValueOf4], timeout: 10)
    }
    
    func testCreateSelector8_ShouldEvaluateOnNewHomeScoreOnly() {
        var transformFuncExecutions = 0
        var selectorEmissions = 0

        func sumString(_ score1: Int, _ score2: Int, _ score3: Int, _ score4: Int, _ score5: Int, _ score6: Int, _ score7: Int, _ score8: Int) -> String {
            transformFuncExecutions += 1
            return "Score is \(score1 + score2 + score3 + score4 + score5 + score6 + score7 + score8)"
        }
        // Define selector
        let getSum = createSelector(getHomeScore, getHomeScore, getHomeScore, getHomeScore, getHomeScore, getHomeScore, getHomeScore, getHomeScore, transformation: sumString)
        
        // Use selector
        store.select(getSum)
            .sink(receiveValue: {_ in selectorEmissions += 1 })
            .store(in: &cancellableSet)
        
        // Dispatch 1 home action and 4 away actions
        store.dispatch(action: Away.Score())
        store.dispatch(action: Home.Score())
        store.dispatch(action: Away.Score())
        store.dispatch(action: Away.Score())
        store.dispatch(action: Away.Score())
        
        // When away score reaches 4, assert home selector only triggered twice:
        // Once with initial store value, once when home score changed.
        let expectationReceiveValueOf4 = expectation(description: "receiveValueOf4")
        store.filter { state in state.away.score == 4 }
            .sink(receiveValue: { state in
                XCTAssertEqual(1, state.home.score)
                XCTAssertEqual(4, state.away.score)
                XCTAssertEqual(2, transformFuncExecutions)
                XCTAssertEqual(2, selectorEmissions)
                self.store.select(getSum)
                    .sink(receiveValue: { sumString in
                        XCTAssertEqual("Score is 8", sumString)
                        expectationReceiveValueOf4.fulfill()
                    }).store(in: &self.cancellableSet)
            }).store(in: &cancellableSet)
        
        wait(for: [expectationReceiveValueOf4], timeout: 10)
    }
    
    func testCreateSelector9_ShouldEvaluateOnNewHomeScoreOnly() {
        var transformFuncExecutions = 0
        var selectorEmissions = 0

        func sumString(_ score1: Int, _ score2: Int, _ score3: Int, _ score4: Int, _ score5: Int, _ score6: Int, _ score7: Int, _ score8: Int, _ score9: Int) -> String {
            transformFuncExecutions += 1
            return "Score is \(score1 + score2 + score3 + score4 + score5 + score6 + score7 + score8 + score9)"
        }
        // Define selector
        let getSum = createSelector(getHomeScore, getHomeScore, getHomeScore, getHomeScore, getHomeScore, getHomeScore, getHomeScore, getHomeScore, getHomeScore, transformation: sumString)
        
        // Use selector
        store.select(getSum)
            .sink(receiveValue: {_ in selectorEmissions += 1 })
            .store(in: &cancellableSet)
        
        // Dispatch 1 home action and 4 away actions
        store.dispatch(action: Away.Score())
        store.dispatch(action: Home.Score())
        store.dispatch(action: Away.Score())
        store.dispatch(action: Away.Score())
        store.dispatch(action: Away.Score())
        
        // When away score reaches 4, assert home selector only triggered twice:
        // Once with initial store value, once when home score changed.
        let expectationReceiveValueOf4 = expectation(description: "receiveValueOf4")
        store.filter { state in state.away.score == 4 }
            .sink(receiveValue: { state in
                XCTAssertEqual(1, state.home.score)
                XCTAssertEqual(4, state.away.score)
                XCTAssertEqual(2, transformFuncExecutions)
                XCTAssertEqual(2, selectorEmissions)
                self.store.select(getSum)
                    .sink(receiveValue: { sumString in
                        XCTAssertEqual("Score is 9", sumString)
                        expectationReceiveValueOf4.fulfill()
                    }).store(in: &self.cancellableSet)
            }).store(in: &cancellableSet)
        
        wait(for: [expectationReceiveValueOf4], timeout: 10)
    }
    
    // MARK: - ofTypes
    
    static func createPublisher(from action: Action) -> AnyPublisher<Action, Never> {
        return Just(action).eraseToAnyPublisher()
    }
    
    func testOfTypes2() {
        let action1 = ReCombineTests.createPublisher(from: Action1())
        let action2 = ReCombineTests.createPublisher(from: Action2())
        let action3 = ReCombineTests.createPublisher(from: Action3())
        let actionStream = Publishers.Merge3(action1, action2, action3).eraseToAnyPublisher()
        
        let expectationValuesCollected = expectation(description: "valuesCollected")
        
        actionStream.ofTypes(Action1.self, Action2.self)
            .collect()
            .sink(receiveValue: { filteredActions in
                XCTAssertEqual(2, filteredActions.count)
                XCTAssertTrue(filteredActions[0] is Action1)
                XCTAssertTrue(filteredActions[1] is Action2)
                expectationValuesCollected.fulfill()
            }).store(in: &cancellableSet)
        
        wait(for: [expectationValuesCollected], timeout: 10)
    }
    
    func testOfTypes3() {
        let action1 = ReCombineTests.createPublisher(from: Action1())
        let action2 = ReCombineTests.createPublisher(from: Action2())
        let action3 = ReCombineTests.createPublisher(from: Action3())
        let action4 = ReCombineTests.createPublisher(from: Action4())
        let actionStream = Publishers.Merge4(action1, action2, action3, action4).eraseToAnyPublisher()
        
        let expectationValuesCollected = expectation(description: "valuesCollected")
        
        actionStream.ofTypes(Action1.self, Action2.self, Action3.self)
            .collect()
            .sink(receiveValue: { filteredActions in
                XCTAssertEqual(3, filteredActions.count)
                XCTAssertTrue(filteredActions[0] is Action1)
                XCTAssertTrue(filteredActions[1] is Action2)
                XCTAssertTrue(filteredActions[2] is Action3)
                expectationValuesCollected.fulfill()
        }).store(in: &cancellableSet)
        
        wait(for: [expectationValuesCollected], timeout: 10)
    }
    
    func testOfTypes4() {
        let action1 = ReCombineTests.createPublisher(from: Action1())
        let action2 = ReCombineTests.createPublisher(from: Action2())
        let action3 = ReCombineTests.createPublisher(from: Action3())
        let action4 = ReCombineTests.createPublisher(from: Action4())
        let action5 = ReCombineTests.createPublisher(from: Action5())
        let actionStream = Publishers.Merge5(action1, action2, action3, action4, action5).eraseToAnyPublisher()
        
        let expectationValuesCollected = expectation(description: "valuesCollected")
        
        actionStream.ofTypes(Action1.self, Action2.self, Action3.self, Action4.self)
            .collect()
            .sink(receiveValue: { filteredActions in
                XCTAssertEqual(4, filteredActions.count)
                XCTAssertTrue(filteredActions[0] is Action1)
                XCTAssertTrue(filteredActions[1] is Action2)
                XCTAssertTrue(filteredActions[2] is Action3)
                XCTAssertTrue(filteredActions[3] is Action4)
                expectationValuesCollected.fulfill()
        }).store(in: &cancellableSet)
        
        wait(for: [expectationValuesCollected], timeout: 10)
    }
    
    func testOfTypes5() {
        let action1 = ReCombineTests.createPublisher(from: Action1())
        let action2 = ReCombineTests.createPublisher(from: Action2())
        let action3 = ReCombineTests.createPublisher(from: Action3())
        let action4 = ReCombineTests.createPublisher(from: Action4())
        let action5 = ReCombineTests.createPublisher(from: Action5())
        let action6 = ReCombineTests.createPublisher(from: Action6())
        let actionStream = Publishers.Merge6(action1, action2, action3, action4, action5, action6).eraseToAnyPublisher()
        
        let expectationValuesCollected = expectation(description: "valuesCollected")
        
        actionStream.ofTypes(Action1.self, Action2.self, Action3.self, Action4.self, Action5.self)
            .collect()
            .sink(receiveValue: { filteredActions in
                XCTAssertEqual(5, filteredActions.count)
                XCTAssertTrue(filteredActions[0] is Action1)
                XCTAssertTrue(filteredActions[1] is Action2)
                XCTAssertTrue(filteredActions[2] is Action3)
                XCTAssertTrue(filteredActions[3] is Action4)
                XCTAssertTrue(filteredActions[4] is Action5)
                expectationValuesCollected.fulfill()
        }).store(in: &cancellableSet)
        
        wait(for: [expectationValuesCollected], timeout: 10)
    }
    
    static var allTests = [
        ("testInitialState", testInitialState),
        ("testDispatch_HomeScore_IncrementsState", testDispatch_HomeScore_IncrementsState),
        ("testDispatch_AwayScore_IncrementsState", testDispatch_AwayScore_IncrementsState),
        ("testDispatch_ResetScore_ResetsState", testDispatch_ResetScore_ResetsState),
        ("testEffects_ShouldDispatch", testEffects_ShouldDispatch),
        ("testEffects_ShouldNotDispatch", testEffects_ShouldNotDispatch),
        ("testRegister_EffectShouldDispatchForLifetimeOfCancellable", testRegister_EffectShouldDispatchForLifetimeOfCancellable),
        ("testCreateSelector1_ShouldEvaluateOnNewHomeScoreOnly", testCreateSelector1_ShouldEvaluateOnNewHomeScoreOnly),
        ("testCreateSelector2_ShouldEvaluateOnNewHomeScoreOnly", testCreateSelector2_ShouldEvaluateOnNewHomeScoreOnly),
        ("testCreateSelector3_ShouldEvaluateOnNewHomeScoreOnly", testCreateSelector3_ShouldEvaluateOnNewHomeScoreOnly),
        ("testCreateSelector4_ShouldEvaluateOnNewHomeScoreOnly", testCreateSelector4_ShouldEvaluateOnNewHomeScoreOnly),
        ("testCreateSelector5_ShouldEvaluateOnNewHomeScoreOnly", testCreateSelector5_ShouldEvaluateOnNewHomeScoreOnly),
        ("testCreateSelector6_ShouldEvaluateOnNewHomeScoreOnly", testCreateSelector6_ShouldEvaluateOnNewHomeScoreOnly),
        ("testCreateSelector7_ShouldEvaluateOnNewHomeScoreOnly", testCreateSelector7_ShouldEvaluateOnNewHomeScoreOnly),
        ("testCreateSelector8_ShouldEvaluateOnNewHomeScoreOnly", testCreateSelector8_ShouldEvaluateOnNewHomeScoreOnly),
        ("testCreateSelector9_ShouldEvaluateOnNewHomeScoreOnly", testCreateSelector9_ShouldEvaluateOnNewHomeScoreOnly),
        ("testOfTypes2", testOfTypes2),
        ("testOfTypes3", testOfTypes3),
        ("testOfTypes4", testOfTypes4),
        ("testOfTypes5", testOfTypes5),
    ]
}
