title: "Metaprogramming Ruby, Part 1: Introduction"
date: 2015-02-04 08:34:47
category: Metaprogramming Ruby
tags: [Ruby,Metaprogramming,Book]
---

## 说在前面
最近在研读《Metaprogramming Ruby》这本书，爱不释手，简直要拍案叫绝了。这本书在很多点上都完全颠覆了我对Ruby肤浅的理解。所以，想开Metaprogramming Ruby系列来进行记录总结，感兴趣的童鞋直接读原书就好，我这里只是会简要概括书中的知识体系。

这一篇作为全系列的开篇，主要来对一些基本概念做些介绍，相信很多人都跟之前的我一样，觉得元编程是一种高大上的技术，但它具体是什么，怎么来实现的，应该用在什么样的场景，对于这些问题很可能一头雾水，那我们就带着问题一起进入元编程的世界吧。<!--more-->

## 概念

 1. Language construct（语言构件）: 类、变量、方法等构成代码的组件
 2. Introspection（内省）：运行时读取语言构件
 
```ruby
# An simple example to explain introspection
class SomeClass
  def initialize(text)
    @text = text
  end

  def welcome
    @text
  end
end

2.0.0-p247 :005 > object = SomeClass.new("Hello Metaprogramming")
=> #<SomeClass:0x007fc5948c9608 @text="Hello Metaprogramming"> 
2.0.0-p247 :006 > object.class
=> SomeClass
2.0.0-p247 :008 > object.class.instance_methods(false)
=> [:welcome]
2.0.0-p247 :009 > object.instance_variables
=> [:@text]
```


## 什么是元编程（Metaprogramming）？
	
	粗略地说，支持编写能够编写代码的代码
	确切地说，支持编写能够在运行时操纵（读写）语言构件的代码
	
具体可细分为静态元编程和动态元编程，前者主要通过编译时代码生成器和编译器实现（属于广义的元编程范畴），后者通过运行时操纵代码实现，本文中的元编程主要介绍后者，即狭义上的元编程（因为Ruby没有编译这个阶段嘛）
     


## 元编程可以用来干哪些具体的事？

 - 元编程技术可以用于创建DSL，解决特定领域的问题
 - 元编程技术可以用来实现能够转发方法调用的包装器，同时能够自动支持方法的添加，ActiveRecord中Model就是一个具体实例，Model就是一个包装器，table中新增的字段会自动映射到Model上。
 - 元编程技术可以用于高效地定义和调用方法
 - 元编程技术可以用于扩展语言本身提供的能力，比如增强一个类（Array,String等）、增强一个方法等

## DSL又是什么？元编程与DSL又有什么关系？

 - DSL是专门为了解决特定领域问题的而设计的语言，比如。。。Rails便是Ruby在Web开发领域的DSL，Gradle是Groovy语言在build system领域的DSL
 - 可以利用元编程技术创建DSL

## Ruby中的元编程是什么样子的？
 - Ruby的元编程特性继承自Lisp和SmallTalk
 - Ruby中尽量为程序员提供强大的元编程能力
 - Ruby支持动态元编程，即在运行时操纵代码

## Ruby中的元编程与其它语言有何不同？  

 - 诸如C++的模板技术以及Java中的注解技术，都属于静态元编程的范畴，能力有限。
 - Ruby支持强大的动态元编程，在运行时具有巨大的能力。
 - 运行时能够操纵语言构件的能力：Ruby > Java > C++ > C


## Ruby中的元编程被应用在何处？
 - 无所不在，框架、类库等
 - ActiveRecord的设计,我们将在这个系列的后续文章中详细介绍元编程技术在ActiveRecord中的应用


## Reference
1. [《Ruby元编程》](http://book.douban.com/subject/7056800/)


Have Fun!

<center>
![卧舟杂谈](/img/58a1d13a6c923c68fc000003.png)
订阅我的微信公众号，您将即时收到新博客提醒！
</center>
