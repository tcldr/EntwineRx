//
//  File.swift
//  
//
//  Created by Tristan Celder on 17/06/2019.
//

import XCTest
import Combine
import RxSwift
import EntwineTest

@testable import EntwineRx

final class RxToCombineTests: XCTestCase {
    
    // MARK: - Properties
    
    var scheduler: TestScheduler!
    
    // MARK: - Per test set-up and tear-down
    
    override func setUp() {
        scheduler = TestScheduler(initialClock: 0)
    }
    
    // MARK: - Tests
    
    func testBasicCase() {
        
        let results1 = scheduler.createTestableSubscriber(Int.self, Never.self)
        let subject = PublishSubject<Int>()
        let sut = subject.bridgeToCombine().mapError { _ -> Never in fatalError() }
        
        scheduler.schedule(after: 100) { sut.subscribe(results1) }
        scheduler.schedule(after: 200) { subject.onNext(0) }
        scheduler.schedule(after: 300) { subject.onNext(1) }
        scheduler.schedule(after: 400) { subject.onNext(2) }
        
        let expected: [TestableSubscriberEvent<Int, Never>] = [
            .init(100, .subscribe),
            .init(200, .input(0)),
            .init(300, .input(1)),
            .init(400, .input(2)),
        ]
        
        scheduler.resume()
        
        XCTAssertEqual(expected, results1.events)
    }
    
    static var allTests = [
        ("testBasicCase", testBasicCase),
    ]
}
