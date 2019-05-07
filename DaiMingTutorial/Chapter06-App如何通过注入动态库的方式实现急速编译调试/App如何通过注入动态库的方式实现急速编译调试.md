#  06 | App如何通过注入动态库的方式实现急速编译调试

文章提及三种注入的实际场景：

1. Swift Playground，然没有说实现原理；
2. Flutter Hot Reload，作为跨平台方案"新秀“，目前势头很猛，之前也跟随官方文档把教程过了一遍（官方文档整体来看不错，非常适合我这种入门菜鸟，加上环境部署，IDE安装花了差不多一星期），之后本来想学习下Flutter渲染底层原理，因为说到它都会提及Flutter自己底层实现了一套渲染机制，但是最后不了了之。
   * [ ] 【待研究】Flutter 热更新机制：**点击 reload 时对比上次编译以后改动过的代码，重新编译涉及到的代码库，还包括主库，以及主库依赖的库。所有这些重新编译过的库都会转成内核文件发到Dart VM中， Dart VM会重新加载新的内核文件，加载后让 Flutter framework触发所有 Widgets 和Render Objects进行重建、重新布局、重新绘制。**
3. Injection for Xcode，这个从插件时代就在使用，现在 John Holdsworth 已经开发了一款Mac App，内部同样是开了一个服务，通过 Socket 和App通信交换 dylib 动态库；
   1. **如何监听？**以Mac App为例，会让你选择项目文件目录，一旦目录中有文件变动就会触发一次增量编译，重新编译成dylib动态库，通过socket发送给App。这个实现不难，后面会补上；
   2. **如何替换？**Client 端接收后自然就要把旧类替换掉，这里使用方法交换就可以了；

## Injection 实现原理剖析

之前小组分享过这个，如果让你来实现动态注入、热更新，如何做呢？分几个关键步骤：

1. 首先监听项目中的文件变化，包括文件的增删、改动，这个Mac已经有现成的实现，按下不表；
2. 增量编译？但是有个问题，改动的文件大部分情况都会`#import`一些依赖文件，这个时候编译怎么玩？文件是编译成`.o`目标文件吗？
3. 安装到模拟器中的App程序已经运行起来了，想要把改动 apply 到程序中，只能借助 dyld，dlopen打开动态库即可，因此上面编译出来的产物最后应该是一个 `.dylib`动态库文件；
4. 通过socket将动态库发送给应用程序，这里自然还得靠客户端App协助才能实现，我们的项目中必须也要开启一个Socket服务，项目中必须加这段代码： ` [[NSBundle bundleWithPath:@"/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle"] load];`
5. 最后就是借助 method swizzle 方法替换即可；



### 1. 如何监听项目文件夹状态变更？

### 2. 如何编译动态库以及在项目中加载动态库使用？

苹果的动态库有`.a`和`.dylib` 两种，编译器可以将单个或多个文件编译成`.o`目标文件，之前文章说到目标文件包含 `undefined symbol`，这些只能等到链接时候才能确定。实际上 `.a` 和 `.dylib`动态库不过是`.o`文件的集合。

使用动态库的优点：

1. 文件体积小；
2. 只需编译部分改动，省时间；
3. 动态升级；

动态库 dylib 需要使用 dyld 动态链接器，这个二进制文件位于 `/usr/bin` 目录下，提供标准的加载和链接功能，寻找，加载，链接动态库，下面内容由 [https://makezl.github.io/2016/06/27/dylib/](https://makezl.github.io/2016/06/27/dylib/)一文总结，内容非常赞，dyld加载顺序：

1. 当任何一个新的进程开始时，内核设置用户模式的入口点到`__dyld_start（dyldStartup.s）`。该函数简单的设置stack然后跳转到`dyldbootstrap::start()`，又跳转到加载器的`_main()`。
2. Dyld的`_main()`函数`（dyld.cpp）`调用 `link()`，`link()` 然后调用一个 `ImageLoader` 对象的 `link()` 方法来启动主程序的连接进程。
3. `ImageLoader` 类`（ImageLoader.cpp）`中可以发现很多由dyld调用来实现二进制加载逻辑的函数。比如，该类中包含 `link()` 方法。当被调用时这个方法又调用对象的 `recursiveLoadLibraries()` 方法来进行了所有需求动态库的加载。
4. ImageLoader的`recursiveLoadLibraries()`方法确定所有需要的库，然后调用`context.loadLibrary()`来逐个加载。context对象是一个简单的结构体，包含了在方法和函数之间传递的函数指针。这个结构体的loadLibrary成员在 `libraryLocator()` 函数（dyld.cpp）中初始化，它完成的功能也只是简单的调用 `load()`函数。
5. load()函数（dyld.cpp）调用各种帮助函数，`loadPhase0()`到`loadPhase5()`。每一个函数都负责加载进程工作的一个具体任务。比如，解析路径或者处理会影响加载进程的环境变量。
6. 在`loadPhase5()`之后，`loadPhase6()`函数从文件系统加载需求的dylib到内存中。然后调用一个`ImageLoaderMachO`类的实例对象。来完成每个dylib对象Mach O文件具体的加载和连接逻辑。

查看 Mach-O可执行文件使用到的 dylib 和 framework；

```
1. 命令行: otool -L yourApp.app/yourApp
2. 用MachOView视图工具, File->Open->YourApp.app/yourApp
```

动态库加载顺序：

1. 首先会加载系统级别的dylib, 目录在设备的`/usr/lib/`, 文件:`libsqlite3.dylib、libc++.1.dylib...`
2. 然后加载系统级别的framework, 目录在设备的`/System/Library/Frameworks`, 文件:`Foundation.framework`
3. 再引入runtime、gcd存放的dylib, 目录在设备的`/usr/lib/`, 文件:`libSystem.B.dylib、libobjc.A.dylib`
3. 再引入自己注入的dylib, `@executable_path/`(目录存放在当前可执行文件底下)

> 摘自wiki：**Mach-O**为**Mach** [**O**bject](https://zh.wikipedia.org/wiki/目标文件)文件格式的[缩写](https://zh.wikipedia.org/wiki/缩写)，它是一种用于[可执行文件](https://zh.wikipedia.org/wiki/可执行文件)，[目标代码](https://zh.wikipedia.org/wiki/目标代码)，[动态库](https://zh.wikipedia.org/wiki/函式庫)，[内核转储](https://zh.wikipedia.org/wiki/核心文件)的文件格式。作为[a.out](https://zh.wikipedia.org/wiki/A.out)格式的替代，Mach-O提供了更强的扩展性，并提升了[符号表](https://zh.wikipedia.org/wiki/符号表)中信息的访问速度。

可以看到 Mach-O 作为一种文件格式，既可以存储可执行文件，也可以是目标代码.o，以及动态库，每个Mach-O文件包含了一个 Mach-O头（`mach_header`），然后是一系列的载入命令(`load_commands`)，再是一个或多个块(`segment`)，每个块包含0到255个段。Mach-O使用REL再定位格式控制对符号的引用。Mach-O在两级命名空间中将每个符号编码成“对象-符号名”对，在查找符号时则采用线性搜索法。

* **load_commands**: 是包含了App所有引用到的dylib与framework. **otool -L** 这个命令行是通过读取Mach-O里面的**load_commands**来展示的；
* **segment**: 一个可执行文件包含多个段，在每一个段内有一些片段。它们包含了可执行文件的不同的部分, 包含了部分的源码及DATA.

dylib结构体定义在 `<mach-o/loader.h>`文件中，app启动的时候，会加载**ImageLoader **`mach_header`中的dylib（这里存疑，感觉应该是`load_commands`包含了引用到的动态库，需要看下dyld的源码）, 每个dylib中的cmd状态为**LC_LOAD_DYLIB**就会被加载.

```c
struct dylib_command { 
  uint_32 cmd; 
  uint_32 cmdsize; 
  struct dylib dylib; 
};

struct dylib { 
  union lc_str name; 
  uint_32 timestamp;
  uint_32 current_version; 
  uint_32 compatibility_version; 
};
```

`dylib_command`中的`cmd`定义

```c
#define LC_REQ_DYLD 0x80000000

/* Constants for the cmd field of all load commands, the type */
#define	LC_SEGMENT	0x1	/* segment of this file to be mapped */
#define	LC_SYMTAB	0x2	/* link-edit stab symbol table info */
#define	LC_SYMSEG	0x3	/* link-edit gdb symbol table info (obsolete) */
#define	LC_THREAD	0x4	/* thread */
#define	LC_UNIXTHREAD	0x5	/* unix thread (includes a stack) */
#define	LC_LOADFVMLIB	0x6	/* load a specified fixed VM shared library */
#define	LC_IDFVMLIB	0x7	/* fixed VM shared library identification */
#define	LC_IDENT	0x8	/* object identification info (obsolete) */
#define LC_FVMFILE	0x9	/* fixed VM file inclusion (internal use) */
#define LC_PREPAGE      0xa     /* prepage command (internal use) */
#define	LC_DYSYMTAB	0xb	/* dynamic link-edit symbol table info */
#define	LC_LOAD_DYLIB	0xc	/* load a dynamically linked shared library */
#define	LC_ID_DYLIB	0xd	/* dynamically linked shared lib ident */
#define LC_LOAD_DYLINKER 0xe	/* load a dynamic linker */
#define LC_ID_DYLINKER	0xf	/* dynamic linker identification */
#define	LC_PREBOUND_DYLIB 0x10	/* modules prebound for a dynamically */

#define	LC_ROUTINES	0x11	/* image routines */
#define	LC_SUB_FRAMEWORK 0x12	/* sub framework */
#define	LC_SUB_UMBRELLA 0x13	/* sub umbrella */
#define	LC_SUB_CLIENT	0x14	/* sub client */
#define	LC_SUB_LIBRARY  0x15	/* sub library */
#define	LC_TWOLEVEL_HINTS 0x16	/* two-level namespace lookup hints */
#define	LC_PREBIND_CKSUM  0x17	/* prebind checksum */

/*
* load a dynamically linked shared library that is allowed to be missing
* (all symbols are weak imported).
*/
#define	LC_LOAD_WEAK_DYLIB (0x18 | LC_REQ_DYLD)
```

当dylib_command中的cmd的状态为**LC_LOAD_DYLIB**加载命令声明了一个所需的动态库, 如果未找到dylib就会抛出异常.
如果是**LC_LOAD_WEAK_DYLIB**声明的库就是可选的, 未找到也不会有什么影响.

#### 2.1 制作dylib 库

假设我们要制作一个math库，只是简单的加减乘数：

```c
#include <stdio.h>

int my_add(int a, int b){
    return a+b;
}

int my_sub(int a, int b){
    return a-b;
}

// ...
```

紧接着将`math.c`文件编译成 `.o`文件，之前说过dylib不过就是`.o`文件的集合，使用gcc命令编译即可：

```shell
gcc -c math.c -o math.o
// 将math.o 做成dylib库
gcc math.o -dynamiclib -current_version 1.0 -o libmath.dylib
```

接下来我们开始使用制作好的库，先写一个test.c文件来调用动态库中定义的函数：

```c
#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>

int main(int argc,char *argv[]){
    int a,b;
    a=10;
    b=9;
    int c;
    c = my_add(a,b);
    printf("%d\n",c);
    return 0;
}
```

可以看到我这边并没有使用 `dlopen` 方法，而是直接调用库中的 `my_add` 方法！这样是可以的，只需要在编译的时候指定库就可以：

```shell
# Linux下的库文件命名有一个约定，即库文件以lib三个字母开头，因为所有的库文件都遵循这个约定，故在用-l选项指定链接的库文件名时可以省去lib三个字母。
gcc test.c -o test -L. -lmath 
# -L 指定目录 . 就是当前目录
# -l 就是库名称，上面是libmath.dylib 取math就好了
```

dlopen方式使用dylib稍有不同，编译时候不需要指定刚才的math库了，而是需要指定ld库！现在写一个testdlopen.c文件测试：

```c
#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>

typedef int (*FUNC)(int,int);

int main(int argc,char *argv[]) {
    
    FUNC add_fpt;
    
    void *h = dlopen("./libmath.dylib",RTLD_LAZY);
    
    add_fpt = dlsym(h,"my_add");
    
    printf("10+12=%d\n",add_fpt(10,12));
    
    dlclose(h);
    
    return 0;
}
```

然后编译测试源文件：

```shell
gcc testdlopen.c -o testdlopen -ldl

./testdlopen
10+12=22
```

基本就是这些内容，附上一些觉得有帮助的参考文章：

* [采用dlopen、dlsym、dlclose加载动态链接库【总结】](https://www.cnblogs.com/Anker/p/3746802.html)
* [如何在Mac OSX 中制作dylib和使用dylib](https://blog.csdn.net/ssihc0/article/details/17299381)
* [MAC制作dylib文件详细步骤](https://blog.csdn.net/Z_dong_dong/article/details/51435847)

以及一些gcc命令：

```shell
# 源文件编译成二进制文件
# 注意这里的 -o 选项意思 
# -o <file>  Write output to <file>
# 可以直接输出二进制文件 也可以是.o目标文件
gcc -o hello hello.c 
# -c 选项也非常重要 需要记忆下： 预处理->编译->汇编
# -c Only run preprocess, compile, and assemble steps
# gcc 提供了支持每个单独的处理步骤，也可以从任意一个步骤开始执行到结束
# 预处理
gcc -E hello.c -o hello.i
# 生成汇编代码
gcc -S hello.i
# 可以一步到位生成可执行文件 a.out
gcc -c hello.c
# 可以生成目标文件
gcc -c hello.c –o hello.o # 源文件->目标文件
gcc -c hello.i -o hello.o # 将预处理过的文件->目标文件
gcc -c hello.c -o hello # 这里颠倒-o -c 位置是ok的

# 多个文件编译，其实搞懂-o -c两个选项的意义，对于记忆是非常有帮助的，-o是output输出的意思， -c是compile编译的意思：
gcc -c main.c foo.c def.c -o foo
```

指定依赖的编译:

```shell
# 假设源文件引用了一个位于/path/to/headerfile/def.h
# 单独使用-l选项表示指定了头文件，如果配合-L就不一样了 见下
gcc foo.c -l /path/to/headerfile/def.h -o foo
# 使用-L -l  
gcc test.c -L. -lmath -o test 
# 之前说的都是动态库 .dylib .so ，现在说说静态库 .a 文件 gcc默认动态库优先，若想在动态库和静态库同时存在的时候链接静态库需要指明为-static选项
gcc foo.c –L /path/to/lib –static –ldef.a –o foo
```

> 那么Injection 应该使用的自然是 dlopen方式喽，毕竟第一种方式是在编译时候就指定了库，而后者是lay load，用到的时候才 dlopen 加载进来。

#### 2.2 iOSOpenDev 和 MoneyDev 创建一个 Hook ViewController 的dylib

可以使用 iOSOpenDev这个开发模板，[这里给个pkg安装地址](http://iosopendev.com/download/)，此刻会安装失败，解决方法请查看 [wiki](https://gist.github.com/ashish1405/8744a1cf9d3d78af3a75559042f7eb54)。我使用的是 brew 安装的dpkg，以及 ldid。安装过程有点不顺利，需要耐心点按照文档步骤来就可以了，一切完毕再次点击iOSOpenDev模板的pkg时，居然还是失败了💥💥！！

![](https://camo.githubusercontent.com/3a0deb2c2ddc2f0ace1dce5b20185dda8b2f048f/687474703a2f2f696f736f70656e6465762e636f6d2f696d6167652f77696b692f496e7374616c6c65724661696c732e6a7067)

此时首先确认问题，按cmd+L查看，或者直接打开Xcode新建一个工程看一下模板有没有。如果有了就可以使用 CaptainHookTweak模板。

<details><summary>点击展开源代码</summary>

```objective-c
#import <Foundation/Foundation.h>
#import "CaptainHook/CaptainHook.h"
#include <notify.h> // not required; for examples only

// Objective-C runtime hooking using CaptainHook:
//   1. declare class using CHDeclareClass()
//   2. load class using CHLoadClass() or CHLoadLateClass() in CHConstructor
//   3. hook method using CHOptimizedMethod()
//   4. register hook using CHHook() in CHConstructor
//   5. (optionally) call old method using CHSuper()


@interface SecondDylib : NSObject

@end

@implementation SecondDylib

-(id)init
{
	if ((self = [super init]))
	{
	}

    return self;
}

@end


@class ViewController;

CHDeclareClass(ViewController); // declare class

CHMethod(0, void, ViewController, viewDidLoad){
    CHSuper(0, ViewController, viewDidLoad);
    
    id view = [self valueForKey:@"view"];
    id color = objc_msgSend(NSClassFromString(@"UIColor"), @selector(redColor));
    ((void (*)(id, SEL,Class))objc_msgSend)(view, @selector(setBackgroundColor:),color);
}

__attribute__ ((constructor)) static void entry(){
    CHLoadLateClass(ViewController);
    CHClassHook(0, ViewController, viewDidLoad);
}

```

</details>






### 3. 如何创建 Server 和 Client Socket通信？

### 4. 如何将动态库中的新代码替换旧的？







































