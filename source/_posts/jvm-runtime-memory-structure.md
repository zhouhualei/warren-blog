title: "Deep in JVM, Part 1: JVM Runtime Memory Structure"
date: 2015-03-22 23:55:58
category: Deep in JVM
tags: [java,JVM,Book]
---

## 说在前面
最近重新开始读《深入理解Java虚拟机》这本书，重新回顾JVM的一些细节，并且用一个系列的blog文章帮助自己整理思路也方便日后温习。说起Java，很多人开始不屑一顾，但是对于JVM，偏见估计会少了些，因为现在的JVM已经是大家的JVM了，Groovy、Scala、Clojure、JRuby等遍地开发，JVM家族一片欣欣向荣，所以理解JVM是如何工作的必然对开发者有莫大的好处。这一篇就先从JVM的内存结构讲起。<!--more-->

## 整体结构

![《JVM虚拟机规范V2》中规定的JVM运行时的内存区域划分](/img/jvm-runtime-memory-structure-1.jpg)



![Sun Hotspot JVM的具体实现](/img/jvm-runtime-memory-structure-2.jpg)


## Program Counter Register

学过CPU芯片组成的童邪应该都会清楚程序计数器了，这里也一样，每个Java线程都需要它来指示当前需要执行的字节码指令，所以它必须是线程私有的。


## JVM Stacks

通常，函数或者方法的执行都需要依赖栈。JVM中也一样，每个Java方法的执行都需要创建一个Stack Frame入栈，并在执行结束后出栈。栈帧中会存储局部变量表、操作数栈、动态链接、方法出口等信息。
局部变量表中包括了那些基本数据类型、对象类型以及返回地址。


## Native Method Stacks

顾名思义，与JVM栈不同的是，本地方法栈就是用来执行本地方法的栈空间，我们从HotSpot JVM的内存划分中也可以看到，JVM Stacks和Native Method Stacks已经被合并在一起实现了。


## Java Heap

堆，应该是程序员们最关心的区域了，因为Java对象生在这儿，也死在这儿，这里也是GC发生的主要区域。通常来说，抛开JIT编译器的优化不说，所有的对象实例和数组都分配在堆中。

堆又可以分为新生代(New Generation)和老年代(Tenured Generation)，对应的就会采用分代回收的垃圾收集算法，原因在于大多数Java对象朝生暮死，所以新生代的区域往往占用得比较大。

新生代又可以继续细分为Eden, From Suvivor, To Survivor三块区域，默认的比例是8:1:1，对象会被优先分配在Eden区域，suvivor区域的作用跟垃圾收集相关，会在后续的文章中介绍。

![Java Heap的进一步划分](/img/jvm-runtime-memory-structure-3.jpg)

## Method Area

方法区存放了被加载的类信息、常量、静态变量、JIT编译后的代码，这个区域是Heap的逻辑部分。在Hotspot JVM中，方法区也被称为“永久代”，因为方法区中也会进行GC，主要针对常量池和卸载的类型进行回收。

## Summary

本文介绍了Java虚拟机的划分以及各个区域的作用，下一篇将会介绍JVM中的垃圾收集器。

## Reference
1. [《深入理解Java虚拟机》](http://book.douban.com/subject/6522893/)

<center>
![卧舟杂谈](/img/58a1d13a6c923c68fc000003.png)
订阅我的微信公众号，您将即时收到新博客提醒！
</center>
