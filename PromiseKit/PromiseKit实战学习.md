# 【初级入门】PromiseKit 实战练习

新建空 iOS 工程，然后在目录下`pod init` 初始化pod，生成的Podfile中引入PromiseKit:

```ruby
# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target '7-17-PromiseDemo' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

	pod "PromiseKit", "~> 6.8"

end
```

执行`pod install`安装 promiseKit 库，此时会引入 CorePromise 以及 Foundation 扩展 ，本文用到的 Promise 对 NSURLSession 的扩展。

接着在 ViewController 中测试代码：

```swift
import UIKit
import PromiseKit


struct Foo : Decodable {
    let message:String
    let nu:String
    let ischeck:String
    let com:String
    let status:String
    let condition:String
    let state:String
    let data:Array<Dictionary<String,String>>

}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("开始执行异步请求操作")
        firstly {
           URLSession.shared.dataTask(.promise, with:try makeUrlRequest()).validate()
        }.map {
            try JSONDecoder().decode(Foo.self, from: $0.data)
        }.done { value in
            print("value :\(value)")
        }.catch {
            error in
            print(error)
        }
        
        print("这里马上会被执行到")
    }

    func makeUrlRequest() throws -> URLRequest {
        let str = "https://www.kuaidi100.com/query?type=shentong&postid=125262"
        let urlwithPercentEscapes = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let url = URL(string: urlwithPercentEscapes!)
        
        var rq = URLRequest(url: url!)
        rq.httpMethod = "POST"
        rq.addValue("application/json", forHTTPHeaderField: "Content-Type")
        rq.addValue("application/json", forHTTPHeaderField: "Accept")
        //        rq.httpBody = try JSONEncoder().encode(obj)
        return rq
    }
}
```

上面实现了异步发起请求，该请求返回数据，然后JSON解码成Model，接着做其他一些UI刷新操作，当然如果还需要处理错误。