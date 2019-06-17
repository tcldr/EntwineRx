//
//  File.swift
//  
//
//  Created by Tristan Celder on 17/06/2019.
//

import Combine
import RxSwift

public enum RxBridgeFailure: Error {
    case upstreamError(Error)
    case bufferOverflow
}

extension Publishers {
    
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
}

extension ObservableType {
    public func bridgeToCombine() -> Publishers.Buffer<Publishers.RxBridge<Self>> {
        Publishers.RxBridge(upstream: self).buffer(size: 1, prefetch: .byRequest, whenFull: .customError({ return RxBridgeFailure.bufferOverflow }))
    }
}
