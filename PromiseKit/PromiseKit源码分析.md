# PromiseKit源码分析 

## 涉及类分析

### 箱子和密封条的故事

#### 密封条 

枚举类型，字面意思“密封带/密封剂”，它可以封存两种情况：`pending` 暂时挂起处理操作，待执行；`resolved` 已处理，暂时封存**值**。

```swift
enum Sealant<R> {
    case pending(Handlers<R>)
    case resolved(R)
}
```

借助 Swift 枚举特性，绑定了handlers和 泛型R值。前者顾名思义是保存处理操作，因此内部定义有一个闭包类型的数组。

```swift
final class Handlers<R> {
    var bodies: [(R) -> Void] = []
    func append(_ item: @escaping(R) -> Void) { bodies.append(item) }
}
```

#### `Box` 箱子

“密封带” 的作用对象立马就能想到`Box` 箱子。

```swift
class Box<T> {
    func inspect() -> Sealant<T> { fatalError() }
    func inspect(_: (Sealant<T>) -> Void) { fatalError() }
    func seal(_: T) {}
}
```

`inspect` 查看箱中**封存之物**，`seal` 封存类型 `T` 的物件到箱中，注意 `Box` 是个抽象类，因此还需要定义不同状态下的具体的箱子。

* `SealedBox`， 已封存结果值的箱子；
* `EmptyBox`，空箱待封状态，需要将“东西”（暂时不明）放入箱中

#### `SealedBox` 已封存结果值的箱子

`SealedBox`，已封存结果值的箱子，传入 `value:T` 初始化一个箱，实际上等同 `seal` 封存操作；`inspect` 返回封存状态和值。

```swift
final class SealedBox<T>: Box<T> {
    let value: T

    init(value: T) {
        self.value = value
    }

    override func inspect() -> Sealant<T> {
        return .resolved(value)
    }
}
```

#### `EmptyBox` 空箱

`EmptyBox`，空箱(开口状态)和一张密封条(`sealant`，初始为挂起状态)，同时自定义一个 **promiseKit** 专属的并行队列。**原因？**

```swift
class EmptyBox<T>: Box<T> {
    private var sealant = Sealant<T>.pending(.init())
    private let barrier = DispatchQueue(label: "org.promisekit.barrier", attributes: .concurrent)
}
```

重写 `seal` 封存方法。

```swift
override func seal(_ value: T) {
  var handlers: Handlers<T>!
  barrier.sync(flags: .barrier) {
    guard case .pending(let _handlers) = self.sealant else {
      return  
    }
    handlers = _handlers
    self.sealant = .resolved(value)
  }

  if let handlers = handlers {
    handlers.bodies.forEach{ $0(value) }
  }
}
```

> Puzzled（2019/07/10）：空箱的密封方法 `seal` 有点迷，`self.sealant` 在实例化出来时候是 `.pending`，然后枚举持有的 `handlers` 内部是一个空数组 `bodies`，上面马上变更了 `self.sealant` 状态变成了 `resolved`，然后传递值给 `handlers` 中的闭包进行操作。

重写查看箱子封存值方法，没啥好讲

```swift
override func inspect() -> Sealant<T> {
  var rv: Sealant<T>!
  barrier.sync {
    rv = self.sealant
  }
  return rv
}

override func inspect(_ body: (Sealant<T>) -> Void) {
  var sealed = false
  barrier.sync(flags: .barrier) {
    switch sealant {
      case .pending:
      body(sealant)
      case .resolved:
      sealed = true
    }
  }
  if sealed {
    body(sealant)
  }
}
```

### `Resolver` 

`resolver` ，源码注解："An object for resolving promises"，实际上源码中并未有任何具体的解决问题实现。类定义如下：

```swift
public final class Resolver<T> {
    let box: Box<Result<T>>

    init(_ box: Box<Result<T>>) {
        self.box = box
    }

    deinit {
        if case .pending = box.inspect() {
            conf.logHandler(.pendingPromiseDeallocated)
        }
    }
}
```

`final` 关键字修饰，意味着 `Resolver` 类不允许被继承，“垄断”了对 Promise 的处理行为。单看实现，构造方法要求传入一个 `Box` 箱实例对象，并且内部持有之。 `Resolver` 看源码实现并未有任何具体解决问题的实现，它更像是把已经得到的「结果值」或「错误」二次封装成 `Result` 对象，然后再封存到 `EmptyBox` 箱子中。

```swift
func fulfill(_ value: T) {
  box.seal(.fulfilled(value))
}

func reject(_ error: Error) {
  box.seal(.rejected(error))
}

func resolve(_ result: Result<T>) {
  box.seal(result)
}

public enum Result<T> {
    case fulfilled(T)
    case rejected(Error)
}

func resolve(_ obj: T?, _ error: Error?) {
  if let error = error {
    reject(error)
  } else if let obj = obj {
    fulfill(obj)
  } else {
    reject(PMKError.invalidCallingConvention)
  }
}

func resolve(_ obj: T, _ error: Error?) {
  if let error = error {
    reject(error)
  } else {
    fulfill(obj)
  }
}

func resolve(_ error: Error?, _ obj: T?) {
  resolve(obj, error)
}
```

### `Thenable`

`Thenable` 协议定义了可链式的异步操作。

```swift
public protocol Thenable: class {
    associatedtype T

    func pipe(to: @escaping(Result<T>) -> Void)

    var result: Result<T>? { get }
}
```

`pipe` 译为「管道」，异步操作的上游数据会通过 `pipe` 方法传入，然后执行异步操作，最后得到结果值`result`。

`Thenable` 协议的扩展实现：

```swift
func then<U: Thenable>(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ body: @escaping(T) throws -> U) -> Promise<U.T> {
  // 1
  let rp = Promise<U.T>(.pending)
  
  // 2
  pipe {
    switch $0 {
      case .fulfilled(let value):
      on.async(flags: flags) {
        do {
          // 3
          let rv = try body(value)
          guard rv !== rp else { throw PMKError.returnedSelf }
          rv.pipe(to: rp.box.seal)
        } catch {
          rp.box.seal(.rejected(error))
        }
      }
      case .rejected(let error):
      rp.box.seal(.rejected(error))
    }
  }
  return rp
}
```

1. 实例化一个 `Promise` 承诺；
2. `pipe` 要求外部实现，但扩展中 `to: @escaping(Result<T>` 闭包有默认实现。真正的操作**实际上是方法中的 `body` 闭包**！异步操作也是借助了**GCD 队列**。
3. `let rv = try body(value)`  执行异步操作，然后返回下一个 `Thenable` 对象，这样才能用 `rv.pipe(to: rp.box.seal)` 串起来。





































