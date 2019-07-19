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
        
        XCTAssertEqual(results1.recordedOutput, [
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
        
        XCTAssertEqual(results1.recordedOutput, [
            (100, .subscription),
            (200, .input(0)),
            (300, .input(1)),
            (400, .completion(.finished)),
        ])
    }
}
