//
//  File.swift
//  
//
//  Created by Tristan Celder on 17/06/2019.
//

import XCTest
import Combine
import RxSwift
import RxTest

@testable import EntwineRx

final class CombineToRxTests: XCTestCase {
    
    // MARK: - Properties
    
    var scheduler: TestScheduler!
    
    // MARK: - Per test set-up and tear-down
    
    override func setUp() {
        scheduler = TestScheduler(initialClock: 0)
    }
    
    // MARK: - Tests
    
    func testBasicCase() {
        
        let disposeBag = DisposeBag()
        let results1 = scheduler.createObserver(Int.self)
        let subject = PassthroughSubject<Int, Never>()
        
        scheduler.scheduleAt(100) { subject.bridgeToRx().subscribe(results1).disposed(by: disposeBag) }
        scheduler.scheduleAt(200) { subject.send(0) }
        scheduler.scheduleAt(300) { subject.send(1) }
        scheduler.scheduleAt(400) { subject.send(2) }
        
        let expected = [
            Recorded.next(200,  0),
            Recorded.next(300,  1),
            Recorded.next(400,  2),
        ]
        
        scheduler.start()
        
        XCTAssertEqual(expected, results1.events)
    }
    
    func testCompletePropagatesDownstream() {
        
        let disposeBag = DisposeBag()
        let results1 = scheduler.createObserver(Int.self)
        let subject = PassthroughSubject<Int, Never>()
        
        scheduler.scheduleAt(100) { subject.bridgeToRx().subscribe(results1).disposed(by: disposeBag) }
        scheduler.scheduleAt(200) { subject.send(0) }
        scheduler.scheduleAt(300) { subject.send(1) }
        scheduler.scheduleAt(400) { subject.send(completion: .finished) }
        
        let expected = [
            Recorded.next(200,  0),
            Recorded.next(300,  1),
            Recorded.completed(400)
        ]
        
        scheduler.start()
        
        XCTAssertEqual(expected, results1.events)
        
    }
}
