# Testing

## Reducers

Reducers are pure functions, which can easily be tested by providing a state and action, and asserting against the resulting state:

```swift
// Source:
static func reducer(state: State, action: Action) -> State {
    switch action {
        case _ as HomeScore:
            return State(home: state.home + 1, away: state.away)
        case _ as AwayScore:
            return State(home: state.home, away: state.away + 1)
        case _ as ResetScore:
            return State(home: 0, away: 0)
        default:
            return state
    }
}

// Tests:
let mockState = Scoreboard.State(home: 2, away: 1)

func testReducer_HomeScoreAction_IncrementsHomeState() {
    let expect = Scoreboard.State(home: 3, away: 1)
    let result = Scoreboard.reducer(state: mockState, action: Scoreboard.HomeScore())
    XCTAssertEqual(expect, result)
}

func testReducer_AwayScoreAction_IncrementsAwayState() {
    let expect = Scoreboard.State(home: 2, away: 2)
    let result = Scoreboard.reducer(state: mockState, action: Scoreboard.AwayScore())
    XCTAssertEqual(expect, result)
}

func testReducer_ResetScoreAction_ResetsState() {
    let expect = Scoreboard.State(home: 0, away: 0)
    let result = Scoreboard.reducer(state: mockState, action: Scoreboard.ResetScore())
    XCTAssertEqual(expect, result)
}
```

## Selectors

Selectors are pure functions, which can easily be tested by providing a state, and asserting against the computed value:

```swift
// Source:
struct State: Equatable {
    let subtotal: Decimal
    let taxRate: Decimal
}

let getSubtotal = { (state: State) in state.subtotal }
let getTaxRate = { (state: State) in state.taxRate }

let getTotalCost = createSelector(
    getSubtotal,
    getTaxRate,
    transformation: { subtotal, taxRate -> Decimal in
        let total = subtotal * (1 + taxRate)
        return total
    }
)

// Tests:
func testTotalCostSelector() {
    let mockState = State(subtotal: 25.0, taxRate: 0.05)
    let result = getTotalCost(mockState)
    XCTAssertEqual(26.25, result)
}
```

## Effects 

Effects can be tested by observing how it's `source` responds to emitted actions.

The following example Effect calls an API to post scores:

```swift
// Effect Definition

static let postScore = Effect(dispatch: true) { actions in
    actions
        .ofType(PostScore.self)
        .flatMap(getPostAPI)
        .eraseToAnyPublisher()
}

// API Management

static var apiManager: ScoreAPIManager = URLSession.shared

static func getPostAPI(action: PostScore) -> AnyPublisher<Action, Never> {
    return apiManager.postScore(home: action.home, away: action.away)
        .map({ _ in PostScoreSuccess() })
        .replaceError(with: PostScoreError())
        .eraseToAnyPublisher()
}

protocol ScoreAPIManager {
    func postScore(home: String, away: String) -> AnyPublisher<URLSession.DataTaskPublisher.Output, URLSession.DataTaskPublisher.Failure>
}

extension URLSession: ScoreAPIManager {
    func postScore(home: String, away: String) -> AnyPublisher<URLSession.DataTaskPublisher.Output, URLSession.DataTaskPublisher.Failure> {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts")
        var urlRequest = URLRequest(url: url!)
        urlRequest.httpMethod = "POST"
        return dataTaskPublisher(for: urlRequest).eraseToAnyPublisher()
    }
}
```

The following tests create a mock ScoreAPIManager (defined above) to assert the results of the Effect based on the API result:

```swift
func testPostScoreEffect_OnRequestSuccess_DispatchPostScoreSuccess() {
    Scoreboard.apiManager = MockSuccessScoreAPIManager()
    let actions = PassthroughSubject<Action, Never>()
    
    let expectationReceiveAction = expectation(description: "receiveAction")
    cancellable = Scoreboard.postScore.source(actions.eraseToAnyPublisher()).sink { resultAction in
        XCTAssertTrue(resultAction is Scoreboard.PostScoreSuccess)
        expectationReceiveAction.fulfill()
    }
    
    actions.send(Scoreboard.PostScore(home: "0", away: "0"))
    
    wait(for: [expectationReceiveAction], timeout: 10.0)
}

func testPostScoreEffect_OnRequestFailure_DispatchPostScoreSuccess() {
    Scoreboard.apiManager = MockFailureScoreAPIManager()
    let actions = PassthroughSubject<Action, Never>()
    
    let expectationReceiveAction = expectation(description: "receiveAction")
    cancellable = Scoreboard.postScore.source(actions.eraseToAnyPublisher()).sink { resultAction in
        XCTAssertTrue(resultAction is Scoreboard.PostScoreError)
        expectationReceiveAction.fulfill()
    }
    
    actions.send(Scoreboard.PostScore(home: "0", away: "0"))
    
    wait(for: [expectationReceiveAction], timeout: 10.0)
}

// API Mocks

class MockSuccessScoreAPIManager: ScoreAPIManager {
    func postScore(home: String, away: String) -> AnyPublisher<URLSession.DataTaskPublisher.Output, URLSession.DataTaskPublisher.Failure> {
        let output: URLSession.DataTaskPublisher.Output = (data: Data(), response: URLResponse())
        return Just(output).setFailureType(to: URLSession.DataTaskPublisher.Failure.self).eraseToAnyPublisher()
    }
}

class MockFailureScoreAPIManager: ScoreAPIManager {
    func postScore(home: String, away: String) -> AnyPublisher<URLSession.DataTaskPublisher.Output, URLSession.DataTaskPublisher.Failure> {
        return Fail(outputType: URLSession.DataTaskPublisher.Output.self, failure: URLSession.DataTaskPublisher.Failure(.badURL)).eraseToAnyPublisher()
    }
}
```

## Store-dependent types

Types that depend on a `Store` instance can use `MockStore` from the `ReCombineTest` module for unit testing.  See the installation page for how to add the `ReCombineTest` module.

The following view model is used in the [example project](https://github.com/ReCombine/ReCombine-Example-SwiftUI) to show a scoreboard view.

```swift
class ScoreboardViewModel: ObservableObject {
    @Published var homeScore = ""
    @Published var awayScore = ""
    @Published var showAlert = false
    private let store: Store<Scoreboard.State>
    private var cancellableSet: Set<AnyCancellable> = []
    
    init(store: Store<Scoreboard.State> = appStore) {
        self.store = store
        
        // Bind selectors
        store.select(Scoreboard.getHomeScoreString).assign(to: \.homeScore, on: self).store(in: &cancellableSet)
        store.select(Scoreboard.getAwayScoreString).assign(to: \.awayScore, on: self).store(in: &cancellableSet)
        
        // Register PostScoreSuccess Effect
        let showAlert = Effect(dispatch: true) { actions in
            actions.ofType(Scoreboard.PostScoreSuccess.self)
                .receive(on: RunLoop.main)
                .handleEvents(receiveOutput: { [weak self] _ in
                    self?.showAlert = true
                })
                .map { _ in Scoreboard.ResetScore() }
                .eraseActionType()
                .eraseToAnyPublisher()
        }
        store.register(showAlert).store(in: &cancellableSet)
    }
    
    func homeScoreTapped() {
        store.dispatch(action: Scoreboard.HomeScore())        
    }
    
    func awayScoreTapped() {
        store.dispatch(action: Scoreboard.AwayScore())
    }
    
    func postScoreTapped() {
        store.dispatch(action: Scoreboard.PostScore(home: homeScore, away: awayScore))
    }
}
```

The following test class shows testing property bindings, local effects, and action dispatching functions:

```swift
import Combine
@testable import ReCombine_Scoreboard
import ReCombineTest
import XCTest

class ScoreboardViewModelTests: XCTestCase {
    var mockStore: MockStore<Scoreboard.State>!
    var vm: ScoreboardViewModel!
    var cancellableSet: Set<AnyCancellable> = []

    override func setUp() {
        mockStore = MockStore(state: Scoreboard.State())
        vm = ScoreboardViewModel(store: mockStore)
    }

    override func tearDown() {
        cancellableSet = []
    }
    
    // MARK: - Property bindings
    
    func testPropertyBindings() {
        let expectationReceiveHomeScore = expectation(description: "receiveHomeScore")
        vm.$homeScore.sink { score in
            XCTAssertEqual("0", score)
            expectationReceiveHomeScore.fulfill()
        }.store(in: &cancellableSet)
        
        let expectationReceiveAwayScore = expectation(description: "receiveAwayScore")
        vm.$awayScore.sink { score in
            XCTAssertEqual("0", score)
            expectationReceiveAwayScore.fulfill()
        }.store(in: &cancellableSet)
        
        wait(for: [expectationReceiveHomeScore, expectationReceiveAwayScore], timeout: 10.0)
    }
    
    // MARK: - showAlert Effect
    
    func testShowAlert_UpdatesShowAlert_OnPostScoreSuccess() {
        let expectationReceiveValues = expectation(description: "receiveValue")
        vm.$showAlert.collect(2).sink { showAlertValues in
            guard let firstAlertValue = showAlertValues.first,
                let secondAlertValue = showAlertValues.last else { return XCTFail() }
            XCTAssertFalse(firstAlertValue)
            XCTAssertTrue(secondAlertValue)
            expectationReceiveValues.fulfill()
        }.store(in: &cancellableSet)
        
        let expectationReceiveActions = expectation(description: "receiveAction")
        mockStore.dispatchedActions.collect(2).sink { actions in
            guard let firstAction = actions.first,
                let secondAction = actions.last else { return XCTFail() }
            XCTAssertTrue(firstAction is Scoreboard.PostScoreSuccess)
            XCTAssertTrue(secondAction is Scoreboard.ResetScore)
            expectationReceiveActions.fulfill()
        }.store(in: &cancellableSet)
        
        mockStore.dispatch(action: Scoreboard.PostScoreSuccess())
        
        wait(for: [expectationReceiveValues, expectationReceiveActions], timeout: 10.0)
    }
    
    // MARK: - Action dispatching functions

    func testHomeScoreTapped_DispatchesHomeScoreAction() {
        let expectationReceiveAction = expectation(description: "receiveAction")
        mockStore.dispatchedActions.sink { action in
            XCTAssertTrue(action is Scoreboard.HomeScore)
            expectationReceiveAction.fulfill()
        }.store(in: &cancellableSet)
        
        vm.homeScoreTapped()
        
        wait(for: [expectationReceiveAction], timeout: 10.0)
    }
    
    func testAwayScoreTapped_DispatchesAwayScoreAction() {
        let expectationReceiveAction = expectation(description: "receiveAction")
        mockStore.dispatchedActions.sink { action in
            XCTAssertTrue(action is Scoreboard.AwayScore)
            expectationReceiveAction.fulfill()
        }.store(in: &cancellableSet)
        
        vm.awayScoreTapped()

        wait(for: [expectationReceiveAction], timeout: 10.0)
    }
    
    func testPostScoreTapped_DispatchesPostScoreAction() {
        let expectationReceiveAction = expectation(description: "receiveAction")
        mockStore.dispatchedActions.sink { action in
            XCTAssertTrue(action is Scoreboard.PostScore)
            expectationReceiveAction.fulfill()
        }.store(in: &cancellableSet)
        
        vm.postScoreTapped()
        
        wait(for: [expectationReceiveAction], timeout: 10.0)
    }
}

```
