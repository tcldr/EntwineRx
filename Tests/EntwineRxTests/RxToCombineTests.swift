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
        let sut = subject.bridgeToCombine(bufferSize: 1).assertNoFailure()
        
        scheduler.schedule(after: 100) { sut.subscribe(results1) }
        scheduler.schedule(after: 200) { subject.onNext(0) }
        scheduler.schedule(after: 300) { subject.onNext(1) }
        scheduler.schedule(after: 400) { subject.onNext(2) }
        
        scheduler.resume()
        
        XCTAssertEqual(results1.sequence, [
            (100, .subscription),
            (200, .input(0)),
            (300, .input(1)),
            (400, .input(2)),
        ])
    }
    
    func testCompletePropagatesDownstream() {
        
        let results1 = scheduler.createTestableSubscriber(Int.self, Never.self)
        let subject = PublishSubject<Int>()
        let sut = subject.bridgeToCombine(bufferSize: 1).assertNoFailure()
        
        scheduler.schedule(after: 100) { sut.subscribe(results1) }
        scheduler.schedule(after: 200) { subject.onNext(0) }
        scheduler.schedule(after: 300) { subject.onNext(1) }
        scheduler.schedule(after: 400) { subject.onCompleted() }
        
        scheduler.resume()
        
        XCTAssertEqual(results1.sequence, [
            (100, .subscription),
            (200, .input(0)),
            (300, .input(1)),
            (400, .completion(.finished)),
        ])
    }
}
