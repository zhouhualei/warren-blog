---
title: '从Java6到Java8: 你应该知道的JVM新特性'
date: 2017-07-13 14:38:56
category: Deep in JVM
tags: [java,JVM,Java6,Java7,Java8,G1,GC,CMS,Lambda]
---

# 前言

目前公司内部正在推动Java6到Java8的升级，团队内部的部分应用也已经完成升级，这篇文章主要介绍JVM层面从java6到java8有哪些重要的变化。一线开发人员可能会觉得，不对啊，我了解java7和java8新引入的语言特性不就完了，JVM新特性对我日常开发工作貌似没有什么直接关系啊。可是作为有追求的程序员，我们做到了知其然，要是再能做到知其所以然的话，遇到问题时岂不是能更淡定从容些。看完此文，可以帮你回答以下几个问题：

> 1. 动态类型语言在Java7之前和之后分别是如何在JVM上运行的？
> 2. lambda表达式是如何实现的？
> 3. 新一代垃圾收集器G1有哪些优势？
> 4. 永久代为什么要被移除？元空间有什么不同吗？

<!-- more -->

# 一、指令集新成员：invokedynamic
我们先来看看Java7引入的一条新的JVM指令：invokedynamic，这可是JVM被设计出来之后第一次改变指令集，这足以看出这个指令的重要性。

## 为什么需要这条指令？
invokedynamic是一条用来进行方法调用的指令，引入这条新指令说明原来实现方法调用的指令有一定的缺陷。
在Java7之前，JVM中包含了4条方法调用指令，分别是invokestatic、invokespecial、invokevirtual和invokeinterface，它们分别对应静态方法调用、构造方法/父类方法/私有方法调用、普通的类方法调用、接口方法调用四种场景。我们通过一个例子来看看它们存在的问题。

我们通过例子来看看传统的方法调用指令是如何工作的。这是一段简单的Java代码，同时实现不同类型变量的加法操作。

```
// filename: InvokestaticDemo.java, 分别实现整形和字符串类型的相加
public class InvokestaticDemo {

    public static Integer add(Integer x, Integer y)  {
        return x + y;
    }

    public static String add(String x, String y)  {
        return x + y;
    }

    public static void main(String[] args) {
        add(2,3);
        add("2","3");
    }

}
```

执行`javac InvokestaticDemo.java`进行编译得到class文件，再执行`javap -v InvokestaticDemo`我们可以看到对应的字节码，截取最关键的一部分如下：
```
Constant pool:
   #8 = Methodref          #12.#32        // InvokestaticDemo.add:(Ljava/lang/Integer;Ljava/lang/Integer;)Ljava/lang/Integer;
  #11 = Methodref          #12.#35        // InvokestaticDemo.add:(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
  #12 = Class              #36            // InvokestaticDemo 
  #18 = Utf8               add 
  #19 = Utf8               (Ljava/lang/Integer;Ljava/lang/Integer;)Ljava/lang/Integer;
  #20 = Utf8               (Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
  #32 = NameAndType        #18:#19        // add:(Ljava/lang/Integer;Ljava/lang/Integer;)Ljava/lang/Integer;
  #35 = NameAndType        #18:#20        // add:(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;  
  #36 = Utf8               InvokestaticDemo  
{  
  public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=2, locals=1, args_size=1
         0: iconst_2
         1: invokestatic  #3                  // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
         4: iconst_3
         5: invokestatic  #3                  // Method java/lang/Integer.valueOf:(I)Ljava/lang/Integer;
         8: invokestatic  #8                  // Method add:(Ljava/lang/Integer;Ljava/lang/Integer;)Ljava/lang/Integer;
        11: pop
        12: ldc           #9                  // String 2
        14: ldc           #10                 // String 3
        16: invokestatic  #11                 // Method add:(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
        19: pop
        20: return
      LineNumberTable:
        line 12: 0
        line 13: 12
        line 14: 20
}
```

从字节码的第8行和第16行可以看到，因为是调用类静态方法，所以使用invokestatic指令，其后有一个参数，分别对应#8和#11，它们在Constant Pool(常量池)中被定义为是Methodref( 方法引用)。Methodref中包含一个Class参数和一个NameAndType参数，其中NameAndType参数又包含UTF8字符串表示方法名以及另一个UTF8字符串表示方法参数类型。很容易理解，Methodref参数完整定义了一个方法，包括其所在的类、方法名、参数的类型，有了这个方法的定义，我们就可以轻松地找到这个方法进行连接并进行调用了。

那我们来看看同样的代码Groovy可以如何来实现：

```groovy
class GroovyInvokeDynamicDemo {
    def static add(x, y) {
        x + y
    }

    def static void main(String[] args) {
        add(2, 3)
        add("2", "3")
    }
}
```

很容易看到区别吧，Groovy代码中只定义了一个不带类型的add方法，整型变量和字符串类型的变量都可以调用同一个方法完成方法调用。  所以问题来了，JVM传统的方法调用都是在编译阶段就确定了需要调用的方法，所以我需要为不同的类型定义不同的方法，对以Java为代表的静态语言来说这并不是什么问题，但是对于以Groovy为代表的动态语言来说这就成了一个实实在在的问题，他们无法找到合适的方法调用指令动态决定方法引用，只能通过API层面或者解释器层面这种曲线救国的方式在运行时决定要调用的方法。  
总的来说，有很多场景需要更加灵活的方法调用，比如运行时决定方法定义、运行时决定参数类型等等。当然Java API层面可以利用反射和MethodHandle等技术 解决这个问题，但是JVM层面如果无法很好地支持这类通用需求，这会导致动态语言无法享受到JVM上的很多性能优化，作为一个志存高远的运行环境，你总得为其它JVM语言多设身处地地想想吧，不是吗？ 

## invokedynamic是如何解决这个问题的？
为了解决上述的问题，java7引入了invokedynamic在JVM层面支持方法调用的动态化。通过引入新的指令集和新的常量，编译时不再需要确定方法引用，而是由invokedynamic指令在运行时调用bootstrap方法在运行时决定方法的定义。 接下来，我们看两个invokedynamic大展拳脚的场景。

## 场景1：更好地支持动态类型语言

动态类型语言利用invokedynamic可以更容易地移植到JVM上。我们知道JVM被设计成了通用的运行时环境，不同语言都可以在这个跨平台的环境中运行，目前也呈现了一种百花齐放的生气，除了Java外，Groovy、Scala、Clojure、JRuby等语言都可以在JVM平台上运行，这些语言当中，Java、Scala是静态类型语言的代表，Groovy和JRuby是动态类型语言的代表。

那我们先来看看动态类型语言和静态类型语言的区别。

顾名思义，区别在于变量类型是静态和动态。其实这是针对代码运行时来说的，在运行时才确定变量类型的就属于动态类型语言，而在编译时就确定语言类型的属于静态类型语言。两者的优劣简单说起来，以Groovy为代表的动态类型语言因为灵活性，可以提高代码的复用性，减少代码量；以Java为代表的静态类型语言因为编译器就能确定类型，就可以进行类型检查，提前发现编码问题，提高代码质量；两者的优点从反面来看也是对方的缺点。

动态语言由于是在运行时决定参数类型，所以可以利用invokedynamic指令进行方法的动态调用,j具体实现细节我们后面会聊。

### Java7之前动态类型语言是如何运行在JVM上的呢？

我们再来看上面的这段Groovy代码, 在Java6环境下执行时对应的调用栈如下： 

![](/img/5951f7da406ab2572a000000.png)

我们可以看到在main方法和add方法之间插入了好几层方法调用，我们可以猜想这些代码就是用来根据参数类型动态决定要调用的方法的。

我们再用命令`groovyc GroovyInvokeDynamicDemo.groovy`对上述代码编译得到calss文件，然后用`javap -v GroovyInvokeDynamicDemo`查看对应的字节码，以下为截取的其中一段：

```
Constant pool:
    #2 = Class              #1            // GroovyInvokeDynamicDemo  
   #18 = Utf8               $getCallSiteArray
   #19 = Utf8               ()[Lorg/codehaus/groovy/runtime/callsite/CallSite;    
   #20 = NameAndType        #18:#19       // $getCallSiteArray:()[Lorg/codehaus/groovy/runtime/callsite/CallSite;
   #21 = Methodref          #2.#20        // GroovyInvokeDynamicDemo.$getCallSiteArray:()[Lorg/codehaus/groovy/runtime/callsite/CallSite;
   #31 = Utf8               (Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;
   #33 = Utf8               org/codehaus/groovy/runtime/callsite/CallSite
   #34 = Class              #33           // org/codehaus/groovy/runtime/callsite/CallSite
   #35 = Utf8               call
   #36 = NameAndType        #35:#31       // call:(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;  
   #37 = InterfaceMethodref #34.#36       // org/codehaus/groovy/runtime/callsite/CallSite.call:(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

{
  public java.lang.Object add(java.lang.Object, java.lang.Object);
    descriptor: (Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;
    flags: ACC_PUBLIC
    Code:
      stack=3, locals=4, args_size=3
         0: invokestatic  #21                 // Method $getCallSiteArray:()[Lorg/codehaus/groovy/runtime/callsite/CallSite;
         3: astore_3
         4: aload_3
         5: ldc           #32                 // int 0
         7: aaload
         8: aload_1
         9: aload_2
        10: invokeinterface #37,  3           // InterfaceMethod org/codehaus/groovy/runtime/callsite/CallSite.call:(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;
        15: areturn
        16: aconst_null
        17: areturn
}
SourceFile: "GroovyInvokeDynamicDemo.groovy"

```

我们看到add方法的参数类型都是Object，在它内部首先利用invokestatic指令调用了一次$getCallSiteArray()方法获得CallSite(第0行)，最后再利用invokeinterface指令执行CallSite.call()方法完成方法调用(第10行)。org/codehaus/groovy/runtime/callsite/CallSite是groovy语言包提供的一个类，我们大概可以猜测获取CallSite的过程中就确定了调用方法的定义，并且通过CallSite.call()完成真正的方法调用。为了验证这个逻辑，我们再把这段代码通过`jad GroovyInvokeDynamicDemo.class`反编译回来，以下为其中一部分相关代码。

```
// Source File Name:   GroovyInvokeDynamicDemo.groovy
import groovy.lang.GroovyObject;
import org.codehaus.groovy.runtime.ScriptBytecodeAdapter;
import org.codehaus.groovy.runtime.callsite.CallSite;
import org.codehaus.groovy.runtime.callsite.CallSiteArray;

public class GroovyInvokeDynamicDemo implements GroovyObject {

    private static SoftReference $callSiteArray;
    ...
    public static Object add(Object x, Object y)
    {
        CallSite acallsite[] = $getCallSiteArray();
        return acallsite[0].call(x, y);
    }

    public static transient void main(String args[])
    {
        CallSite acallsite[] = $getCallSiteArray();
        acallsite[1].callStatic(GroovyInvokeDynamicDemo, Integer.valueOf(2), Integer.valueOf(3));
    }

    private static void $createCallSiteArray_1(String as[])
    {
        as[0] = "plus";
        as[1] = "add";
    }

    private static CallSiteArray $createCallSiteArray()
    {
        String as[] = new String[2];
        $createCallSiteArray_1(as);
        return new CallSiteArray(GroovyInvokeDynamicDemo, as);
    }

    private static CallSite[] $getCallSiteArray()
    {
        CallSiteArray callsitearray;
        if($callSiteArray == null || (callsitearray = (CallSiteArray)$callSiteArray.get()) == null)
        {
            callsitearray = $createCallSiteArray();
            $callSiteArray = new SoftReference(callsitearray);
        }
        return callsitearray.array;
    }
}


package org.codehaus.groovy.runtime.dgmimpl;

import org.codehaus.groovy.runtime.callsite.CallSite;
import org.codehaus.groovy.runtime.dgmimpl.NumberNumberMetaMethod;
import org.codehaus.groovy.runtime.dgmimpl.NumberNumberMetaMethod.NumberNumberCallSite;
import org.codehaus.groovy.runtime.typehandling.NumberMath;

public final class NumberNumberPlus extends NumberNumberMetaMethod {
    private static class IntegerInteger extends NumberNumberCallSite {
        public IntegerInteger(CallSite site, MetaClassImpl metaClass, MetaMethod metaMethod, Class[] params, Object receiver, Object[] args) {
            super(site, metaClass, metaMethod, params, (Number)receiver, (Number)args[0]);
        }

        public final Object call(Object receiver, Object arg) throws Throwable {
            try {
                if(this.checkCall(receiver, arg)) {
                    return Integer.valueOf(((Integer)receiver).intValue() + ((Integer)arg).intValue());
                }
            } catch (ClassCastException var4) {
                ;
            }

            return super.call(receiver, arg);
        }
    }
```

在反编译后的代码里，我们看到了\$getCallSiteArray()和\$createCallSiteArray()方法，这无疑是groovy编译器加到代码里的。我们继续来看add方法内部调用plus方法(注意：+号操作在groovy里被实现为plus方法调用)的实现细节，通过\$getCallSiteArray()为plus方法返回的CallSite是一个IntegerInteger的实例，很容易理解这是通过参数类型决定的实例。调用call方法的时候真正完成加法操作。

总结一下，java7之前是通过动态语言自己实现CallSite的方式在编辑器层面插入动态方法调用的逻辑。

### Java7之后动态类型语言可以如何利用invokedynamic指令呢？

我们用`groovyc --indy GroovyInvokeDynamicDemo.groovy`命令在java8环境对同一段groovy代码进行编译，再用`javap -v GroovyInvokeDynamicDemo`反编译，得到以下字节码：

```
Constant pool:
   #27 = Utf8               (Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;
   #38 = Utf8               invoke
   #39 = NameAndType        #38:#27       // invoke:(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object; 
   #40 = InvokeDynamic      #0:#39        // #0:invoke:(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;
{
  public static java.lang.Object add(java.lang.Object, java.lang.Object);
    descriptor: (Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=2, locals=2, args_size=2
         0: aload_0
         1: aload_1
         2: invokedynamic #40,  0             // InvokeDynamic #0:invoke:(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;
         7: areturn
         8: nop
         9: athrow
}
BootstrapMethods:
  0: #34 invokestatic org/codehaus/groovy/vmplugin/v7/IndyInterface.bootstrap:(Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;Ljava/lang/String;I)Ljava/lang/invoke/CallSite;
    Method arguments:
      #36 plus
      #37 0
```

可以看到add方法的指令集有了不少精简，与java6环境下的字节码对比，它用一个invokedynamic指令代替了以前invokestatic和invokeinterface组合起来才能完成的事情。从字节码中可以大致看到invokedynamic指令的执行过程。首先，它会先调用BootstrapMethods属性表中的第一个引导方法获得一个CallSite(注意：这里是java/lang/invoke/CallSite)，这里已经包含了具体的方法句柄(MethodHandle)；然后，执行CallSite中获取到的方法句柄。从逻辑上来讲并没有发生太大变化，实现方式上却发生了很大的变化。

总的来说，invokedynamic指令带来的变化是：
> 1. Java API层面，引入CallSite, MethodHandle，将整个方法动态调用的过程标准化
> 2. JVM层面，通过invokedynamic指令简化动态代码调用的字节码

动态脚本语言，通过使用invokeydynamic指令，带来的好处可以用"简单"、"高效"来概括：
> 1. 简单: 标准化动态语言在JVM上的实现过程，简化了动态语言在JVM上的实现
> 2. 高效：直接采用JVM指令可以获得更接近Java的的性能，包括可以享受到JIT优化等

## 场景2：实现lambda表达式

除了对动态语言的支持之外，invokedynamic还为Java8引入lambda语言特性提前做好了JVM层面的准备。那我们就来看看lambda表达式是如何实现的吧。

### 匿名类来实现?

Java8之前，我们也可以利用匿名类来实现类似于lambda表达式的效果(虽然看起来有些笨拙)。所以我们自然而然的猜想，lambda表达式在实现上是不是转换成了匿名类进行实现的。那我们来验证一下，我们用Function类来实现一个函数。
```
// 匿名类风格实现匿名函数 
import java.util.function.Function;
public class InnerClass {
    Function<Object, String> f = new Function<Object, String>() {
        @Override
        public String apply(Object obj) {
            return obj.toString();
        }
    };
}
```
利用javap看到的字节码如下：
```
{
  public InnerClass();
    0: aload_0
    1: invokespecial #1    // Method java/lang/Object."<init>":()V
    4: aload_0
    5: new           #2    // class InnerClass$1
    8: dup
    9: aload_0
    10: invokespecial #3   // Method InnerClass$1."<init>":(LInnerClass;)V
    13: putfield      #4   // Field f:Ljava/util/function/Function;
    16: return
}
```

我们看到第10行的invokespecial指令调用了InnerClass$1类的构造函数进行初始化生成一个f实例，InnerClass$1就是一个匿名类。

### 利用invokedynamic指令实现

```
// lambda风格实现匿名函数 
import java.util.function.Function;
public class Lambda {
    Function<Object, String> f = obj -> obj.toString();
}
```
对应的字节码为：
```
{
  public Lambda();
    0: aload_0
    1: invokespecial #1    // Method java/lang/Object."<init>":()V
    4: aload_0
    5: invokedynamic #2, 0 // InvokeDynamic #0:apply:()Ljava/util/function/Function;
    10: putfield     #3    // Field f:Ljava/util/function/Function;
    13: return
}
BootstrapMethods:
  0: #21 invokestatic java/lang/invoke/LambdaMetafactory.metafactory:(Ljava/lang/invoke/MethodHandles$Lookup;Ljava/lang/String;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodType;Ljava/lang/invoke/MethodHandle;Ljava/lang/invoke/MethodType;)Ljava/lang/invoke/CallSite;
    Method arguments:
      #22 (Ljava/lang/Object;)Ljava/lang/Object;
      #23 invokestatic Lambda.lambda$new$0:(Ljava/lang/Object;)Ljava/lang/String;
      #24 (Ljava/lang/Object;)Ljava/lang/String;
```

invokedynamic指令的工作原理之前已经解释过，通过调用bootstrap方法获得CallSite，然后执行这个CallSite中包含的方法句柄完成方法的调用，调用的结果会返回一个Function的实例。从bootstrap方法的字节码中我们看到

```
#23 invokestatic Lambda.lambda$new$0:(Ljava/lang/Object;)Ljava/lang/String;
```
说明lambda表达式是以类静态方法的形式被调用，对应的代码在逻辑上看起来会是这样的：
```
public class Lambda {
    Function<Object, String> f = [dynamic invocation of lambda$new$0]
    static String lambda$new$0(Object obj) {
        return obj.toString();
    } 
}
```
这段静态代码的字节码是在运行时生成的，因为我们并没有在class文件中找到这个静态方法。后续如果要执行f这个lambda表达式的话，f.apply会代理给CallSite中的方法句柄（也就是Lambda.lambda$new$0这个静态方法）完成lambda表达式的执行。

结论：
从上面两段字节码可以看到两者的差别非常之大，这也从另一个方面证明lambda函数在底层并不是通过匿名类来实现的。为什么这么设计呢？匿名类会为每一个lambda表达式生成一个.class文件，这个从实现上来看不够优雅，性能上也会带来问题。而利用lambda就可以利用invokedynamic指令的动态调用特性实现lambda表达式的调用。

# 二、新的垃圾收集器: G1
JDK 1.7 Update 14开始还引入了一个新的垃圾收集器G1，在此之前，互联网领域很多采用ParNew+CMS的垃圾收集器组合进行分代垃圾回收。

## 为什么需要一种新的垃圾回收器
在平常工作中，我们最害怕的是出现Full GC，Full GC主要会进行老年代的垃圾回收，主流的老年代垃圾回收器CMS虽然设计目标是获得最短的回收停顿时间，但是仍然会导致一定时间的停服务(Stop The World)，所以会影响到服务的正常响应。

CMS对于堆内存的分代管理机制大家应该已经非常熟悉:

![CMS堆内存分代管理](/img/5959b0413dfb5f1969000002.png)

先来看看CMS的运行示意图。

![CMS垃圾回收示意图](/img/5959ad743dfb5f1969000000.png)

CMS全称Concurrent mark Sweep，所以很容易理解其采用的是标记清除的垃圾回收算法，从图中也可以看到整个垃圾回收过程分为五个阶段：初始标记、并发标记、重新标记、并发清理、重置线程。尽管并发标记、并发清理和重置线程已经可以和用户线程同时运行，但是初始标记阶段和重新标记两个阶段是需要停用户线程的。通常，初始标记阶段很快，重新标记阶段相对耗时。对于堆空间很大的场景，这个停服务时间可能就会长到无法接受。

另外一方面，CMS采用的是标记清除算法，这会导致内存碎片的产生，当需要为大对象分配空间时，就会出现找不到连续大空间的情况，这种情况下会触发一次Full GC，经过参数配置，Full GC在垃圾回收之前可以先进行一次内存合并整理，但是合并整理过程是无法需要Stop The World，所以解决了内存碎片问题的同时，又导致额外的停服务时间。

总体来讲，CMS主要的问题在于：
1. 垃圾回收过程依然会停用户服务，如果是大内存场景下发生Full GC，这个时间可能会比较长。
2. 采用标记清除算法，会导致大量的碎片，影响大对象的空间分配。 

## G1的工作机制
G1是一款是以替换CMS为目标并且面向服务端应用的垃圾收集器，它的本质思想是化整为零。如果每次垃圾回收可以选择堆空间的一部分进行回收，那么停顿时间就可以被控制在合理的范围内。

### 化整为零
我们先来看看G1化整为零的设计, 下图是G1中对内容的布局:

![G1 Region划分](/img/5959affd3dfb5f1969000001.png)

在G1中依然是分代回收的概念，但是每一代的空间不再是简单地连续分配，他们被分散成多个大小相等的存储块，每个块都可以进行独立的垃圾回收，他们被称作Region。因为可以独立进行垃圾回收，那就有能力将一次很长的GC分解成多个短GC，通过调整每一次需要回收的Region数量来控制停顿时间的长短。

如何选择需要回收的Region呢？G1采用的是回收价值优先策略，能回收的空间越大，所需时间越短，就会获得较高的优先级而先被回收掉。

化整为零这件事情做起来并不容易，试想要把一棵对象依赖树分割开来，难度可想而知。其实这也不是G1新引入的问题，G1和其它收集器一样都采用了Remembered Set（简称RSet）来避免全堆扫描，本质上就是一种空间换时间算法。逻辑上每个Region都有一个RSet，它能够维护“谁引用了我的对象”这样的信息。所以当对Region内的对象进行可达性分析的时候结合RSet的信息就可以避免对全堆进行扫描了。

### 停顿预测模型

因为做到了化整为零，G1可以建立停顿预测模型。通过参数-XX:MaxGCPauseMillis指定一个收集过程的目标停顿时间。它会对每个Region垃圾回收耗时的历史数据进行分析，建立停顿预测模型，来预测当前时间点对每个Region进行垃圾回收可能消耗的时间，再根据用户设定的目标停顿时间，就可以计算出来需要回收的Region数量。
需要注意的是，因为依赖于根据历史数据预测垃圾回收时间，因此并不能保证百分百的准确性，所以这里的目标停顿时间是一个期望值，并不是硬性条件。

### 标记整理
G1的另一个改进之处在于采用标记整理算法避免内存碎片，以下是G1垃圾回收各阶段的示意图：

![G1垃圾回收示意图](/img/5958867c5d27cb03c3000000.png)

从图中看到，与CMS相比，整个垃圾回收的过程其实没有太多的变化，最重要的变化是采用“标记整理”算法取代了CMS的“标记清除”算法，这个可以解决内存碎片的问题。

总体来说，G1的优势在于：
1. 将垃圾回收化整为零，减少对用户服务的影响
2. 垃圾回收时间可配置
3. 避免内存碎片

# 三、 永久代被逐步移除，引入元空间Metaspace
JDK8之前，堆被分为新生代、老年代; 除了堆之外，JVM中还有永久代，永久代中存放类的元数据(包括类的层级信息、方法数据和方法信息)、类的静态变量、运行时常量池(包括字符串字面量、符号引用)等。其中，类的元数据和静态变量会在类被加载时被分配，类被卸载时被回收；而字符串字面量是在GC的时候就可能被回收。

永久代的移除可以参考下面这张图，新引入的元空间被放在本地内存中进行管理：

![](/img/596580018324b35bee000000.png)

## 永久代有哪些问题？为何需要被移除？
主要有以下几个原因：
1. JVM家族融合趋势，有些JVM没有永久代的设计。
2. 很难确定永久代需要的空间大小，如果设置不合理，会导致OOM。而且永久代的垃圾回收和老年代是绑定的，一旦其中一个占满，就会一起进行GC。
3. 增加了GC实现的复杂度，对永久代中的元数据需要特殊处理

## 如何解决这些问题呢?

永久代的移除和元空间的引入是一个分步骤完成的过程：
1. JDK7中，字符串字面量和类的静态变量首先被从永久代被移出到Java堆中;避免因为字符串字面量大量存储到字符串常量池中而导致的永久代内存溢出。
2. JDK8中，JVM彻底移除了永久代，同时引入元空间(Metaspace)来管理原来的元数据，这些元数据被分配到本地内存中进行管理。元空间默认上限是本地内存大小，所以降低了元空间OOM的可能性。

需要注意的是：因为默认不对元空间大小做限制，所以发生在元空间的内存泄露可能会耗尽内存，所以仍然需要通过监控来避免这种情况的发生。

# Conclusion

总结起来，从Java6到Java8语言特性和JVM内部都有比较大的变化，了解并合理使用这些新特性将会帮助我们解决实际工作中的一些问题。期待Java和JVM生态越来越好。

# Reference

1. [New JDK 7 Feature: Support for Dynamically Typed Languages in the Java Virtual Machine](http://www.oracle.com/technetwork/articles/java/dyntypelang-142348.html)
2. [Invokedynamic 101](http://www.javaworld.com/article/2860079/learn-java/invokedynamic-101.html)
3. [Java 8 实战](https://book.douban.com/subject/26772632/)
4. [深入理解Java虚拟机(第2版)](https://book.douban.com/subject/24722612/)
5. [深入理解Java 7](https://book.douban.com/subject/10734875/)
6. [Java Hotspot G1 GC的一些关键技术](https://zhuanlan.zhihu.com/p/22591838)
7. [JEP 122: Remove the Permanent Generation](http://openjdk.java.net/jeps/122)
8. [Java永久代去哪儿了](http://www.infoq.com/cn/articles/Java-PERMGEN-Removed)
8. [探秘Metaspace](http://www.sczyh30.com/posts/Java/jvm-metaspace/)
9. [Java常量池理解与总结 ](http://www.jianshu.com/p/c7f47de2ee80) 

---


