# 【初级入门】自己实现一个PromiseKit

> 这两天把 WWDC 2019 Session 中的 Combine 基础篇和实践篇看完，大致捋顺了 Combine 中的 Publisher、Subject、Subscriber等知识点，目前Xcode Beta2依旧不支持Session中提到的语法糖，可能要等正式版出来才会全部开放。
>
> 响应式框架 ReactiveCocoa，RxSwift，PromiseKit 早前也有略微了解，不过并没有深入，也没有用其写过项目。这次趁着机会学习一波，探究这几个框架是如何实现“函数式“或”响应式”的，以及框架中哪些是可以值得借鉴学习的。
>
> 第一个拿来“开刀”的是 **PromiseKit**，它是一种设计模式，增强代码可读性和维护性，这一点在之后的学习中体现的尤为明显。作者是 Max Howell 大神，如果表示没听过，那么来说说 `Homebrew` ，这个占据了MacOS中重要的包管理工具总该知道吧！也是出自他手。
>
> 非常感谢[莲叔](https://www.jianshu.com/u/9efd08855d3a)的两篇《Swift脑洞系列》教程，通俗易懂，帮助学习 PromiseKit 实现大有裨益，比直接撸源码要轻松很多，我在学习之后大呼过瘾，打算写篇文章记录下，谈谈自己对PromiseKit的理解，同时用Swift5.1来实现下文中例子。

## 异步操作

> 假设场景：网络请求图片资源，请求完成后更新视图。这里异步操作常用到的有三：设置 delegate 回调，请求完成后，通过 `[_delegate didFinishedTask:]` 告知；请求函数传递 `success` 和 `failed` block 作为成功和失败回调，请求完成后调用该代码块；Notification 通知。

这里以第二种为例：

```swift
func asyncOperation(complete : ()-> Void){
    // 异步执行任务，通常借助 GCD dispatch到 globalQueue 执行任务
 		// 如果不借助GCD，就是自己起一个线程执行任务。
  	// 任务是过程式，即一行行执行代码，执行完毕紧接着调用complete
  	DispatchQueue.global().async {
      // do something ...
    	complete()
    }
}
```

实际开发中常遇到先发请求A，回调中拿参数 X 发请求B，回到中拿参数 Y 发请求 C，如果用伪代码表示就是：

```swift

func requestA(complete : @escaping (String)-> Void){
    DispatchQueue.global().async {
        print("请求A完成")
        complete("A参数")
    }
}

func requestB(complete : @escaping (String)-> Void){
    DispatchQueue.global().async {
        print("请求B完成")
        complete("B参数")
    }
}

func requestC(complete : @escaping (String)-> Void){
    DispatchQueue.global().async {
        print("请求C完成")
        complete("C参数")
    }
}

print("发起请求A")
requestA { (responseA) in
    print("拿请求A的参数\(responseA) 发起请求B")
    
    requestB { (responseB) in
        print("拿请求B的参数\(responseB) 发起请求C")
        
        requestC { (responseC) in
            print("All Request Done")
        }
    }
}

RunLoop.main.run()

//=========== 输出 ============
/*
发起请求A
请求A到来
拿请求A的参数A参数 发起请求B
请求B到来
拿请求B的参数B参数 发起请求C
请求C到来
All Request Done
*/ 
//=============================
```

如果去掉`print` 日志信息，那么由requestA作为发起的嵌套请求-回调将是噩梦（`callback hell`）：

```swift
requestA { (responseA) in
    requestB { (responseB) in
        requestC { (responseC) in
            print("All Request Done")
        }
    }
}
```

既然这么写会导致 callback hell ，那么我们就得换一种表现上简洁、易懂的写法，当然是本质不会变的，依旧是异步+回调。

明确下一个进行异步操作的方法是怎么样的：

```swift
func asyncOperation(complete : ()-> Void){
    // 异步执行任务，通常借助 GCD dispatch到 globalQueue 执行任务
 		// 如果不借助GCD，就是自己起一个线程执行任务。
  	// 任务是过程式，即一行行执行代码，执行完毕紧接着调用complete
  	DispatchQueue.global().async {
      // do something ...
    	complete()
    }
}
```

方法会提供一个 `complete` 闭包，这里类型定义比较简单:`(String)-> Void`，方法内部的异步实现这里用到了 GCD，返回值为 `Void`。因此简单的异步操作方法的类型为：

```swift
typealias AsyncFunc = ((String)->Void) -> Void
```

这里的 `asyncOperation` 方法就是 `AsyncFunc` 类型，它接收`()->Void`函数指针参数，返回值为空。

> 我们定制了两个异步操作的执行顺序(**这一点相当重要**)，规则1：第一个异步操作完成后，在`complete`闭包中执行下一个异步操作；规则2：两个异步操作同时进行，但是必须等两个操作都完成后才能执行下一步操作。



**实现规则一：第一个异步操作完成，执行下一个异步操作。**

现在我们将两个**异步操作** ”揉“成一个操作，但这个操作是“冷”的，并未被执行。而揉成的新操作内部持有两个异步操作，以我们约定的规则进行调用。

```swift
func concat(left:AsyncFunc,right:AsyncFunc) -> AsyncFunc {
    return {
        complete in
        
    }
}
```

按照之前说的我们将两个异步操作传入，“揉”成一个新的异步操作返回，这个方法命名为 `concat`，实现模板如上。

方法具体的实现规则是先调用 left 异步操作，完成后再调用 right 异步操作，两者都完成了才执行complete闭包，这个是新操作开放给外部的接口——允许用户在两个异步操作完成后执行一些其他事务项。

```swift
func concat(left:@escaping AsyncFunc,right:@escaping AsyncFunc) -> AsyncFunc {
    return {
        complete in
      	// 《=== 1. 调用 left 异步操作
        left { // 《=== 2. 这里传入的是 left 异步操作的 complete 闭包，执行的是调起 right闭包
            _ in 
          	// 《=== 3. 正如你所看到这里调用 right 异步操作
            right { // 《=== 4. 这里同样传入的 right 异步操作的 complete 闭包，表明两个操作都完成时应该执行开放给外部的 complete 闭包
                _ in
                complete("all done")
            }
        }
    }
}
```

仔细阅读下上面的注释应该可以简单理解这里的思想。

```swift
let concatedFunction = concat(asyncOperation, 
                               right: asyncOperation1)
```









# Reference

* [【Swift脑洞系列】轻松无痛实现异步操作串行](https://www.jianshu.com/p/168f92164f06)

* [【Swift 脑洞系列】并行异步运算以及100行的`PromiseKit`](https://www.jianshu.com/p/656bebe7aa6e)