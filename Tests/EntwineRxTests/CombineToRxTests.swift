//
//  EntwineRx
//  https://github.com/tcldr/EntwineRx
//
//  Copyright © 2019 Tristan Celder. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

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
