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

import Combine
import RxSwift

extension ObservableType {
    
    /// A bridging operator that transforms an RxSwift `ObservableType` into a Combine `Publisher`.
    ///
    /// Note: A legal combine `Publisher` must limit its production to the level specified by a `Subscriber`
    /// whereas an RxSwift `Observable` has no such restriction. Therefore, this operator maintains a buffer
    /// of elements from the upstream `Observable` to store until requested.
    ///
    /// To avoid out-of-memory errors, and constrain resource usage in general, it is recommended to provide
    /// a conservative value for `bufferSize` matching the expected output of the upstream `Observable`
    /// and consumption of the downstream `Subscriber`.
    ///
    /// - Parameter bufferSize: The size of the element buffer.
    /// - Parameter whenFull: The strategy to employ for handling subsequent elements if the buffer
    /// reaches capacity
    public func bridgeToCombine(bufferSize: Int, whenFull: RxBridgeBufferingStrategy = .fail) -> Publishers.Buffer<RxBridge<Self>> {
        RxBridge(upstream: self).buffer(size: bufferSize, prefetch: .byRequest, whenFull: whenFull.bufferingStrategy )
    }
}

/// `Failure` type of the `RxBridge` publisher.
///
/// Either:
/// - An `Error` forwarded from a upstream `Observable`, or
/// –  A notice that the publisher terminated the subscription due to the upstream `Observable` emitting at a greater
/// rate than was specified when the publisher was created.
///
public enum RxBridgeFailure: Error {
    case upstreamError(Error)
    case bufferOverflow
}

/// Buffering strategy options for the `.bridgeToCombine(bufferSize:whenFull:)` operator.
///
/// When the buffer is full, for subsequent upstream elements:
/// - `.dropNewest`: will discard additional elements.
/// - `.dropOldest`: will purge the oldest element and append the new element to the buffer.
/// - `.fail`: will complete the `Publisher` with a `RxBridgeFailure.bufferOverflow` and
/// end the sequence.
///
public enum RxBridgeBufferingStrategy {
    case dropNewest
    case dropOldest
    case fail
}

// MARK: - Publisher definition

public struct RxBridge<Upstream: ObservableType>: Publisher {
    
    public typealias Output = Upstream.Element
    public typealias Failure = RxBridgeFailure

    let upstream: Upstream

    init(upstream: Upstream) {
        self.upstream = upstream
    }

    public func receive<S : Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
        subscriber.receive(subscription: RxBridgeSubscription(upstream: upstream, downstream: subscriber))
    }
}

// MARK: - Publisher subscription

fileprivate final class RxBridgeSubscription<Upstream: ObservableType, Downstream: Subscriber>: Subscription where Upstream.Element == Downstream.Input, Downstream.Failure == RxBridgeFailure {
    
    enum Status {
        case pending
        case active(RxBridgeSink<Upstream, Downstream>)
        case complete
    }
    
    let upstream: Upstream
    let downstream: Downstream
    var status = Status.pending
    
    init(upstream: Upstream, downstream: Downstream) {
        self.upstream = upstream
        self.downstream = downstream
    }
    
    // There's nothing we can do to satisfy a request for a finite demand
    // as RxSwift doesn't have intrinsic backpressure support. However, if
    // we _know_ that the subscriber is in fact a `Buffer` sink (enforced
    // by the API keeping the initialiser to the operator internal, and
    // only exposing the `ObservableType` factory method) we can guarantee
    // legal behavior. Now, our only responsibility is to ensure we only
    // start the subscription when we reach a demand threshold of one
    func request(_ demand: Subscribers.Demand) {
        guard case .pending = status, demand > .none else { return }
        status = .active(RxBridgeSink(upstream: upstream, downstream: downstream))
    }
    
    func cancel() {
        status = .complete
    }
}

// MARK: - Publisher Sink

fileprivate final class RxBridgeSink<Upstream: ObservableType, Downstream: Subscriber>: ObserverType where Upstream.Element == Downstream.Input, Downstream.Failure == RxBridgeFailure {
    
    typealias Element = Upstream.Element
    
    let downstream: Downstream
    var disposable: Disposable?
    
    init(upstream: Upstream, downstream: Downstream) {
        self.downstream = downstream
        self.disposable = upstream.subscribe(self)
    }
    
    deinit {
        disposable?.dispose()
    }
    
    func on(_ event: Event<Upstream.Element>) {
        switch event {
        case .next(let value):
            _ = downstream.receive(value)
        case .error(let error):
            downstream.receive(completion: .failure(.upstreamError(error)))
        case .completed:
            downstream.receive(completion: .finished)
        }
    }
}

// MARK: - RxBridgeBufferingStrategy to Publishers.BufferingStrategy

extension RxBridgeBufferingStrategy {
    var bufferingStrategy: Publishers.BufferingStrategy<RxBridgeFailure> {
        switch self {
        case .fail:
            return .customError { .bufferOverflow }
        case .dropNewest:
            return .dropNewest
        case .dropOldest:
            return .dropOldest
        }
    }
}
