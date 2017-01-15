# OperationKit

A Swift framework inspired by WWDC 2015 Advanced NSOperations session. 

## Requirements

- iOS 8.0+ 
- Xcode 8.1+
- Swift 3.0+

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate OperationKit into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
	pod 'OperationKit', '~> 2.1'
end
```

Then, run the following command:

```bash
$ pod install
```
## Usage

`Operation` is an `Foundation.Operation` subclass. It is an abstract class which should be subclassed.

```swift
import OperationKit

class FooOperation: Operation {
    override func execute() {
        print("running")
        finish()
    }
}

let operationQueue = OperationQueue()
let fooOperation = FooOperation()
operationQueue.addOperation(fooOperation)
```

## Observers

Observers are attached to an `Operation`. They receive callbacks when operation events occur.:

```swift
operation.addObserver(BlockObserver { operation, _ in
	print("finished")	                  
})
```

OperationKit also provides `TimeoutObserver` and `NetworkObserver`.

## Conditions

Conditions are attached to an `Operation`. Before an operation is ready to execute it will asynchronously *evaluate* all of its conditions. If any condition fails, the operation finishes with an error instead of executing. For example:

```swift
let urlRequestOperation = URLRequestOperation(request: request)
urlRequestOperation.addCondition(ReachabilityCondition(host: request.url!))
``` 

### Making a Request

```swift
import OperationKit

let operationQueue = OperationKit.OperationQueue()
let dataRequestOperation = DataRequestOperation(request: request)
operationQueue.addOperation(operationQueue)
```

### Response Handling

Handling the `Response` of a `DataRequest` made in OpertationKit is easy.

```swift
dataRequestOperation.responseJSON { result in
	switch result {
		  case let .success(responseJSON):
				print(responseJSON)
                
           case let .failure(_error):
               print("error")
    }
}
```
