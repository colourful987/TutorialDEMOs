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
3. `let rv = try body(value)`  执行异步操作，然后返回下一个 `Thenable` 对象，这样才能用 `rv.pipe(to: rp.box.seal)` 串起来。 **这里疑问`body`闭包要求返回一个 `Thenable` 对象，如果`body`是我们想要异步执行的操作，返回值应该由调用方决定返回什么，所以这里大胆先猜测要么是约定，要么并不是什么具体的异步操作。**

`map` 方法官方说明“The provided closure is executed when this promise is resolved.”  

> 这里 `map` 方法泛型` U `并不需要遵循 `Thenable` 协议，`map` 更多地是将值类型变换的过程。

```swift
func map<U>(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(T) throws -> U) -> Promise<U> {
  let rp = Promise<U>(.pending)
  pipe {
    switch $0 {
      case .fulfilled(let value):
      on.async(flags: flags) {
        do {
          // 1
          rp.box.seal(.fulfilled(try transform(value)))
        } catch {
          // 2
          rp.box.seal(.rejected(error))
        }
      }
      case .rejected(let error):
      // 3
      rp.box.seal(.rejected(error))
    }
  }
  return rp
}
```

> 1，2，3 简单理解就是往 EmptyBox 中封存了一个 Result 结果值，可能是`fulfilled` 也可能是 `rejected`。

「compact」译为 「紧凑的」，可选类型值就像一个充气的塑料袋，我们“啪”一下将其拍扁，剔除 `nil` 值的情况。 `compactMap` 和 `map` 其实是差不多的，差别就在于 `transform` 得到值的处理，若未`nil` 会抛出错误。

```swift
func compactMap<U>(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ transform: @escaping(T) throws -> U?) -> Promise<U> {
  let rp = Promise<U>(.pending)
  pipe {
    switch $0 {
      case .fulfilled(let value):
      on.async(flags: flags) {
        do {
          if let rv = try transform(value) {
            rp.box.seal(.fulfilled(rv))
          } else {
            throw PMKError.compactMap(value, U.self)
          }
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

`done` 方法时机在于 promise 被解决时调用。对照 `then` 方法，注意 `body(value) ` 执行完就没事了，而 `then` 需要用 `pipe` 串联起来。

```swift
func done(on: DispatchQueue? = conf.Q.return, flags: DispatchWorkItemFlags? = nil, _ body: @escaping(T) throws -> Void) -> Promise<Void> {
  let rp = Promise<Void>(.pending)
  pipe {
    switch $0 {
      case .fulfilled(let value):
      on.async(flags: flags) {
        do {
          try body(value)
          rp.box.seal(.fulfilled(()))
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

`get` 方法应用场景是想在pipe管道的某个处理环节取值，但又不想影响整个流程。源码实现 `try body($0)` 看上去像是切片方法提供给外部调用，闭包内部最后返回的是$0，并没有做任何修改。

```swift
func get(on: DispatchQueue? = conf.Q.return, flags: DispatchWorkItemFlags? = nil, _ body: @escaping (T) throws -> Void) -> Promise<T> {
  return map(on: on, flags: flags) {
    try body($0)
    return $0
  }
}
```

`tap` 是想获得 `Result<T>` 值，和`get` 方法作用类型，在分析它源码前先看下 Promise 提供的一种构造方法，方便之后理解，构造器的入参是一个闭包，类型是接收一个 `Resolver`，方法内部先实例化一个 box 和 resolver，然后调用 `body` 闭包。

```swift
public init(resolver body: (Resolver<T>) throws -> Void) {
  box = EmptyBox()
  let resolver = Resolver(box)
  do {
    try body(resolver)
  } catch {
    resolver.reject(error)
  }
}
```

现在再看 `tap` 方法实现，代码片段1就理解了，`pipe` 协议方法要由具体类来实现，它的定义为：`func pipe(to: @escaping(Result<T>) -> Void)`，就是个闭包对象，笔者简单看了下 Promise 对 `Thenable` 协议的实现:

```swift
public func pipe(to: @escaping(Result<T>) -> Void) {
  switch box.inspect() { // 1 <---- 打开箱子看看里面有啥
    case .pending:	// 2 <---- 是挂起状态的，note: 可是绑定了 handlers 对象
    	// 3. Begin --------------------------------
      box.inspect {
        switch $0 {
          case .pending(let handlers):
          	handlers.append(to)
          case .resolved(let value):
          	to(value)
        }
      }
    	// 3. End --------------------------------
    case .resolved(let value): // 4 <---- 打开来发现是已经解决了 那么直接调用 to(value) 执行
    	to(value)
  }
}
```

简单的笔者都注释了，片段3是 `inspect` 以闭包方式开放给外部来操作箱子绑定的 `Sealant` 密封条，如果是 `.pending` 那么就将 `to` 操作暂时放入 `handlers` 中，否则直接执行，这个实际上等同于代码片段4。

**疑问：**若是 `.pending` 状态下，仅仅是 `handlers.append(to)`，并未执行 `to()` 闭包，`Begin - End` 这段代码已经被保存到 `handlers` 数组中安排之后某个时机执行，而外部传入的  `body` 闭包，此刻**也被持有——但是未执行**，前面个时刻会取出 `EmptyBox` 中的 `Sealant` 密封条，它有两种状态：`case pending(Handlers<R>) 和 case resolved(R)`。

```swift
func tap(on: DispatchQueue? = conf.Q.map, flags: DispatchWorkItemFlags? = nil, _ body: @escaping(Result<T>) -> Void) -> Promise<T> {
  return Promise { seal in   // 1. <---- seal 是一个 resolver
   		pipe { // <---------------- Begin ----------------
     			result in 
        			// <-----2 注意这里我们又构建了一个异步操作！
        			// 执行到这里 说明此刻是 .resolved 状态，取出了里面的值 Result 类型
        			// 调用持有的 body 闭包，然后 resolver 修改 box 的密封的结果值
        			on.async(flags: flags) {
             		  body(result)
              		seal.resolve(result)
         			}
        			// <------2 End
      		}// <---------------- End ----------------
   }
}
```

> 看到这里，其实我对 Sealant 和 Result 还是有点迷糊，光看源码会将两者混起来，我知道 Box 要有一个密封条，要么是挂起状态，要么就是解决了的状态。如果是挂起，那么就把操作加入到 pending 绑定的handlers 中；如果是解决，就把Result类型的结果值绑定到 `.resolved` 枚举中。而这个操作独立出一个 Resolver 来看这件事。
>
> ```swift
> enum Sealant<R> {
>     case pending(Handlers<R>)
>     case resolved(R)
> }
> 
> public enum Result<T> {
>     case fulfilled(T)
>     case rejected(Error)
> }
> ```



将 Promise 的链式传递值给断掉！官方解释：“a new promise chained off this promise but with its value discarded.”

```swift
func asVoid() -> Promise<Void> {
  return map(on: nil) { _ in }
}
```

`Thenable` 对 `Sequence` 类型做了一些扩展，这些都是高等函数，对于结果值（Result 枚举绑定值）为数组类型，间接调用了系统提供的 `map`，`flatMap`，`filter` 函数。

* `mapValues`

  ```swift
  firstly {
    .value([1,2,3])
  }.mapValues { integer in
    integer * 2
  }.done {
    // $0 => [2,4,6]
  }
  ```

* `flatMapValues`

  ```swift
  firstly {
   .value([1,2,3])
  }.flatMapValues { integer in
   [integer, integer]
  }.done {
   // $0 => [1,1,2,2,3,3]
  }
  ```

* `compactMapValues`

  ```swift
  firstly {
   .value(["1","2","a","3"])
  }.compactMapValues {
   Int($0)
  }.done {
   // $0 => [1,2,3]
  }
  ```

* `thenMap`

  ```swift
  firstly {
   .value([1,2,3])
  }.thenMap { integer in
   .value(integer * 2)
  }.done {
   // $0 => [2,4,6]
  }
  ```

* `thenFlatMap`

  ```swift
  firstly {
   .value([1,2,3])
  }.thenFlatMap { integer in
   .value([integer, integer])
  }.done {
   // $0 => [1,1,2,2,3,3]
  }
  ```

* `filterValues`

  ```swift
  firstly {
   .value([1,2,3])
  }.filterValues {
   $0 > 1
  }.done {
   // $0 => [2,3]
  }
  ```

  

`Thenable` 对 `Collection` 类型做的扩展：

* `firstValue`
* `lastValue`

### Promise 「我对你的承诺」

> Promise 「我对你的承诺」，终将有果，或兑现，或拒绝，无论好坏，**我都轻轻地放入箱中**；
>
> 对你的承诺不限次数，无法拒绝；每个请求都给与承诺，**一个接一个**；并不是每个承诺都能被兑现，所以我随机应变，下一个承诺我会随之改变，一切只为了你。

Promise 类会持有一个 Box 存放或好或坏的结果，遵循 `Thenable` 协议让承诺串起来进行履行。

```swift
public final class Promise<T>: Thenable, CatchMixin {
    let box: Box<Result<T>>

    fileprivate init(box: SealedBox<Result<T>>) {
        self.box = box
    }
		
    public init(resolver body: (Resolver<T>) throws -> Void) {
        box = EmptyBox()
        let resolver = Resolver(box)
        do {
            try body(resolver)
        } catch {
            resolver.reject(error)
        }
    }
  	//....
}
```

`Resolver` 不关心承诺的具体内容是什么，不关心你是如何去尝试兑现这个承诺的，它只是机械的将你尝试兑现承诺的结果 `Result<T>` 写入到它持有的 Box 中，`fulfill` 兑现了，`reject` 就是拒绝了，回顾下代码：

```swift
/// Fulfills the promise with the provided value
func fulfill(_ value: T) {
  box.seal(.fulfilled(value))
}

/// Rejects the promise with the provided error
func reject(_ error: Error) {
  box.seal(.rejected(error))
}
```

当然 `Resolver` 还提供了其他便利方法，但是归根结底都是调用上述两个方法，或者直接操作 box 实例塞东西。而 promise 承诺在完成之时（成功or失败）都需要将其结果写入到box中，这部分职责划分给了 Resolver。

接着来说下 Promise 对 `Thenable` 协议中的 `pipe` 方法的实现：

```swift
public func pipe(to: @escaping(Result<T>) -> Void) {
  switch box.inspect() {
    case .pending:
    box.inspect {
      switch $0 {
        case .pending(let handlers):
        handlers.append(to)
        case .resolved(let value):
        to(value)
      }
    }
    case .resolved(let value):
    to(value)
  }
}
```

1. 拿到密封箱，此刻忍不住想要看看 “密封” 情况（`enum Sealant`）：`.pending(Handlers<R>)` 或是 `.resolved(R)`；
2. IF `.pending`，说明此刻的箱子还“开口”状态，我们的密封条绑定的 `handlers` 中还有未执行的操作闭包，没办法，我们只能将 `to` 闭包暂时也 `append` 到密封条中的 `handlers` 的 `body` 数组；
3. `body.inspect{}` 闭包中对 `.resolved` 处理涉及到 barrier 问题，正常想法是既然进入到这里应该状态就是 `.pending`，但实际上可能多线程情况下不是哦。<—— 这里还是存疑下；
4. `.resolved` 处理，这个没有问题

Promise 提供了 `wait` 方法，会阻塞当前线程，所以最好不用在 `main` 线程中使用。

```swift
func wait() throws -> T {

  if Thread.isMainThread {
    conf.logHandler(LogEvent.waitOnMainThread)
  }

  var result = self.result

  if result == nil {
    let group = DispatchGroup()
    group.enter()
    pipe { result = $0; group.leave() }
    group.wait()
  }

  switch result! {
    case .rejected(let error):
    throw error
    case .fulfilled(let value):
    return value
  }
}
```

> Promise 的代码基本上就是这些，至此我还是一脸懵逼，承诺的具体内容？在哪里被调用？这些我似乎都没注意到，看来只能继续源码看下去。注意到 Feature 文件夹，即「主要功能」，这个似乎有点料，打开文件夹赫然入目5个文件，分别是：`hang`， `after`，`firstly`，`race` 和 `when`，几个函数实现都寥寥几行，但是扮演着至关重要的角色，下面逐一学习。

使用 `firstly` 函数是明智的选择，提高代码可读性。当然你也可以不使用，中规中矩地先实例化一个 Promise 对象，然后开始你的表演。函数代码真的寥寥几行：

```swift
public func firstly<U: Thenable>(execute body: () throws -> U) -> Promise<U.T> {
    do {
        let rp = Promise<U.T>(.pending) //1
        try body().pipe(to: rp.box.seal) //2
        return rp
    } catch {
        return Promise(error: error)
    }
}
```

1. 代码片段1中的 Promise 构造方法实例化了一个空箱，而这里的 `.pending` 并非是 `Sealant` 密封条枚举值。

   ```swift
   init(_: PMKUnambiguousInitializer) {
       box = EmptyBox()
   }
   ```

2. 代码片段2中的 `body()` 返回的是一个 `Thenable` 对象；调用  `pipe` 方法，它的类型是 `@escaping (Result<T>) -> Void`，而 `rp.box.seal` 函数的类型为 `func seal(_ value: T) `，省略了 `Void` 返回值，回归下 `EmptyBox` 的 `seal` 方法以及 `Promise` 的 `pipe` 方法：

   ```swift
   /// Promise.swift file
   public func pipe(to: @escaping(Result<T>) -> Void) {
     switch box.inspect() {
       case .pending:
       box.inspect {
         switch $0 {
           case .pending(let handlers):
           handlers.append(to)
           case .resolved(let value):
           to(value)
         }
       }
       case .resolved(let value):
       to(value)
     }
   }
   
   /// Box.swift file
   override func seal(_ value: T) {
     var handlers: Handlers<T>!
     barrier.sync(flags: .barrier) {
       guard case .pending(let _handlers) = self.sealant else {
         return  // already fulfilled!
       }
       handlers = _handlers
       self.sealant = .resolved(value)
     }
   
     if let handlers = handlers {
       handlers.bodies.forEach{ $0(value) }
     }
   
   }
   ```

   暂时不看 `handlers.append` 那段，可以看到 `body().pipe(to: rp.box.seal)` 这段代码应该就是将上一个 `body()` 生成的承诺值传递到新实例化出来的 `rp` 对象的box中，但是这里的调用有点让人一时无法理解，尽管函数类型都匹配上了，但是居然修改了 rp.box 的值，其实转念一想，调用这个方法时候，应该像oc那样第一、二个是隐藏参数 `self` 和 `_cmd`。如果让我这个新手来写应该是这样的：

   ```swift
   try body().pipe(to: { (result) in
        rp.box.seal(result)
   })
   ```

   然后转念一想swift貌似提供了语法糖，只传递函数指针就可以啦，觉得“奇怪”可能是因为这里传递的是实例对象的方法指针，而非之前经常传递 sort，map，filter等一些函数指针。

 



















