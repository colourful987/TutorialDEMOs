# PromiseKit源码分析 

## 涉及类分析

### 箱子和密封条的故事

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
* `EmptyBox`，空箱待封状态；



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

`EmptyBox`，空箱(开口状态)和一张密封条(`sealant`，初始为挂起状态)，同时自定义一个 **promiseKit** 专属的并行队列。**原因？**

```swift
class EmptyBox<T>: Box<T> {
    private var sealant = Sealant<T>.pending(.init())
    private let barrier = DispatchQueue(label: "org.promisekit.barrier", attributes: .concurrent)
}
```

重写 `seal` 封存方法，这里有个疑问：`_handlers` 对象初识情况下，内部`body`是空数组，这里的操作意义何在？应该还有其他地方进行操作枚举了吧。

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

同样重写查看箱子封存值方法：

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





























