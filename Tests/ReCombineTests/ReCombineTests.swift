import Combine
import XCTest
@testable import ReCombine

final class ReCombineTests: XCTestCase {
    
    // Store, Reducer setup
    
    struct ScoreboardState {
        var home = Home.State()
        var away = Away.State()
        var lastAction: Action?
    }
    
    struct ResetScore: Action {}
    
    enum Home {
        struct Score: Action {}
        struct State {
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
    
    enum Away {
        struct Score: Action {}
        struct State {
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
    
    static func lastActionReducer(state: Action?, action: Action) -> Action {
        return action
    }
    
    static let reducer: ReducerFn<ScoreboardState> = combineReducers(
        forKey(\.home, use: Home.reducer),
        forKey(\.away, use: Away.reducer),
        forKey(\.lastAction, use: lastActionReducer)
    )
    
    // Effects setup
    
    struct Action1: Action {}
    struct Action2: Action {}
    
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
            XCTAssertTrue(state.lastAction is Action2)
            expectationReceiveValue.fulfill()
        })
        
        wait(for: [expectationReceiveValue], timeout: 10)
    }
    
    func testEffects_ShouldNotDispatch() {
        let expectationReceiveValue = expectation(description: "receiveValue")
        store.dispatch(action: Action2())
        cancellable = store.sink(receiveValue: { state in
            XCTAssertTrue(state.lastAction is Action2)
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
    
    

    static var allTests = [
        ("testInitialState", testInitialState),
        ("testDispatch_HomeScore_IncrementsState", testDispatch_HomeScore_IncrementsState),
        ("testDispatch_AwayScore_IncrementsState", testDispatch_AwayScore_IncrementsState),
        ("testDispatch_ResetScore_ResetsState", testDispatch_ResetScore_ResetsState),
        ("testEffects_ShouldDispatch", testEffects_ShouldDispatch),
        ("testEffects_ShouldNotDispatch", testEffects_ShouldNotDispatch),
        ("testRegister_EffectShouldDispatchForLifetimeOfCancellable", testRegister_EffectShouldDispatchForLifetimeOfCancellable),
    ]
}
