
# EntwineRx

Part of [Entwine](https://github.com/tcldr/Entwine) – A collection of accessories for [Apple's Combine Framework](https://developer.apple.com/documentation/combine).

---

### CONTENTS
- [About EnwtineRx](#about-entwinerx)
- [Getting Started](#getting-started)
- [Installation](#installation)
- [Documentation](#documentation)
- [Copyright and License](#copyright-and-license)

---

### ABOUT ENTWINE RX
_EntwineRx_ is a lightweight library of two operators to bridge from _RxSwift_ to _Combine_ and back again. You can use _EntwineRx_ to make your existing _RxSwift_ view models and operators work seamlessly with any _Combine_ based code you might be developing.

be sure to checkout the [documentation](http://tcldr.github.io/Entwine/EntwineDocs) for the full list of operators and utilities.

---

### GETTING STARTED

## From _Combine_ to _RxSwift_
The `bridgeToRx()` operator that _EntwineRx_ adds to _Combine_'s `Publisher` type means that you can bridge to _RxSwift_ as simply as:

```swift
import Combine
import RxSwift
import EntwineRx

let myRxObservable = Publishers.Just<Int, Never>(1).bridgeToRx()

```
## From _RxSwift_ to _Combine_
This direction requires a little more thought as we now have to account for _Combine_'s requirement that any publisher obeys its [strict back pressure requirements](#backpressure-and-combine).

As _RxSwift_ has no such restriction we have to give some guidance for how we would like any unrequested elements from our `Observable` stream to be handled. We do this by introducing an element buffer to store our elements until they're requested by a subscriber.

We must then decide:
1. How big that buffer should be
2. What we should do when our buffer is full

As long as we are able to reason about the source of our upstream `Observable`'s elements, and the rate at which we expect our subscriber to consume them – this should be relatively straightforward.

In this case we can safely set a low buffer count, and fail if we enter a situation that is unexpected. (If failing is not an option, you can also choose to drop any new elements or drop the buffer's oldest elements.)

So what number? At least one. And one is often enough. A sequence would require a buffer size of at least the count of the sequence.

```swift
import Combine
import RxSwift
import EntwineRx

// both `.just(_)` and `from(_)` deliver their elements immediately upon subscription – we need a buffer!
let combinePublisher1 = Observable.just(1)
    .bridgeToCombine(bufferSize: 1, whenFull: .fail)

let combinePublisher2 = Observable.from([1,2,3,4,])
    .bridgeToCombine(bufferSize: 4, whenFull: .fail)

```
If the buffer _does_ overflow the publisher will complete with an `RxBridgeFailure.bufferOverflow` failure. From here you can decide how you wish to recover.

If you're feeling especially self-assured you can chain the `.assertBridgeBufferNeverOverflows()` operator after the bridge operator. Be warned though – as the name suggests this will cause an assertion failure if your hypothesis proves incorrect.

---

### BACKPRESSURE AND _COMBINE_

Backpressure is the situation in which a publisher is producing elements faster than a subscriber can consume.

This behavior can result in a scenario where unconsumed elements are building up in the buffer of some publisher faster than they can be processed by a downstream subscriber. This can very quickly consume system resources causing performance degradation – and ultimately out-of-memory errors.

_Combine_ handles backpressure by only allowing a publisher to emit an element if it is has been signalled by its subscriber. A subscriber can signal at any point during the lifetime of a subscription, and may decide not to signal at all. Therefore it is the responsibility of the publisher to limit its output accordingly.

---

### INSTALLATION
### As part of another Swift Package:
1. Include it in your `Package.swift` file as both a dependency and a dependency of your target.

```swift
import PackageDescription

let package = Package(
    ...
    dependencies: [
        .package(url: "http://github.com/tcldr/EntwineRx.git", .upToNextMajor(from: "0.1.0")),
    ],
    ...
    targets: [.target(name: "MyTarget", dependencies: ["EntwineRx"]),
    ]
)
```

2. Then run `swift package update` from the root directory of your SPM project. If you're using Xcode 11 to edit your SPM project this should happen automatically.

### As part of an Xcode 11 or greater project:
1. Select the `File -> Swift Packages -> Add package dependency...` menu item.
2. Enter the repository url `https://github.com/tcldr/EntwineRx` and tap next.
3. Select 'version, 'up to next major', enter `0.1.0`, hit next.
4. Select the _Entwine_ library and specify the target you wish to use it with.


---

### DOCUMENTATION
Full documentation for _EntwineRx_ can be found at [http://tcldr.github.io/Entwine/EntwineRxDocs](http://tcldr.github.io/Entwine/EntwineRxDocs).

---

### COPYRIGHT AND LICENSE
Copyright 2019 © Tristan Celder

_EntwineRx_ is made available under the [MIT License](http://github.com/tcldr/Entwine/blob/master/LICENSE)

---