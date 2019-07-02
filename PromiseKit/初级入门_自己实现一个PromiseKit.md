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









# Reference

* [【Swift脑洞系列】轻松无痛实现异步操作串行](https://www.jianshu.com/p/168f92164f06)

* [【Swift 脑洞系列】并行异步运算以及100行的`PromiseKit`](https://www.jianshu.com/p/656bebe7aa6e)