//
//  File.swift
//  
//
//  Created by Tristan Celder on 17/06/2019.
//

import Combine
import RxSwift

extension Publisher {
    public func bridgeToRx() -> Observable<Output> {
        Observable<Output>.create { observer in
            let cancellable = self.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:             observer.onCompleted()
                    case .failure(let error):   observer.onError(error)
                    }
                },
                receiveValue: { value in
                    observer.onNext(value)
                }
            )
            return Disposables.create { cancellable.cancel() }
        }
    }
}
