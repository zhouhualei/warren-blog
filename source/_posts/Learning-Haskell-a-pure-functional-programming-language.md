title: 'Learning Haskell: a pure functional programming language'
date: 2015-07-19 23:22:20
category: language
tags: [functional, haskell, scala]
---

说在前面
---
最近，Java写恶心了，计划重新捡起丢在一边很久的Scala，但是，Scala是个大怪物，几年前刚接触Scala的时候，认认真真地读过一遍原版《Programming in Scala : A Comprehensive Step-by-step Guide》，但是完全迷失在一堆难于理解的概念中。回头细想，本质上还是缺乏函数式编程的功底。为了更好地理解函数式编程的核心理念，我就用Haskell这门纯粹的函数式语言作为起点，开启我的重拾Scala之路。<!--more-->

Install Haskell Environment in Mac Step By Step
---


```
% brew install ghc cabal-install
```

```
% ghci
GHCi, version 7.8.4: http://www.haskell.org/ghc/  :? for help
Loading package ghc-prim ... linking ... done.
Loading package integer-gmp ... linking ... done.
Loading package base ... linking ... done.
Prelude> 4
4
```

Basic Concepts
---

###定义函数

```
Prelude> let double x = x * 2
Prelude> double 2
4 
```

###定义模块

```
./double.hs
module Main where
    double x = x + x
```

```
Prelude> :load double.hs
[1 of 1] Compiling Main             ( double.hs, interpreted )
Ok, modules loaded: Main.
*Main> double 5
10
```

递归
---

###递归的不同实现 -> 阶乘问题
####一行递归

```
Prelude> let fact x = if x==0 then 1 else fact (x - 1) * x
Prelude> fact 3
6
```
####模式匹配

```
./factorial.hs
module Main where
    factorial :: Integer -> Integer     -- type declaration
    factorial 0 = 1                     -- pattern 1
    factorial x = x * factorial (x - 1) -- pattern 2
```
####哨兵表达式

```
./fact_with_guard.hs
module Main where
    factorial :: Integer -> Integer
    factorial x
        | x > 1 = x * factorial (x - 1)
        | otherwise = 1
```


###高效地处理递归，元祖和列表 -> Example: 斐波那契序列问题
####不够高效的实现：模式匹配

```
./fib.hs
module Main where
    fib :: Integer -> Integer
    fib 0 = 1
    fib 1 = 1
    fib x = fib (x - 1) + fib (x - 2)
```

####高效实现：利用元组，转换为尾递归

```
./fib_tuple.hs
module Main where
    fibTuple :: (Integer, Integer, Integer) -> (Integer, Integer, Integer)
    fibTuple (x, y, 0) = (x, y, 0)
    fibTuple (x, y, index) = fibTuple (y, x + y, index - 1)

    fibResult :: (Integer, Integer, Integer) -> Integer
    fibResult (x, y, z) = x

    fib :: Integer -> Integer
    fib x = fibResult (fibTuple (0, 1, x))
```

####利用函数的组合

```
./fib_pair.hs
module Main where
    fibNextPair :: (Integer, Integer) -> (Integer, Integer)
    fibNextPair (x, y) = (y, x + y)

    fibNthPair :: Integer -> (Integer, Integer)
    fibNthPair 1 = (1, 1)
    fibNthPair n = fibNextPair (fibNthPair (n - 1))

    fib :: Integer -> Integer
    fib = fst . fibNthPair 
```

高阶函数
---

###匿名函数（lambda）

```
Prelude> (\x -> x ++ "World!") "Hello "
"Hello World!"
```

###map

```
-- map + lamda
Prelude> map (\x -> x * x) [1, 2, 3]
[1,4,9]
```

###filter

```
*Main> filter odd [1, 2, 3, 4, 5]
[1,3,5]
```

###flodl, foldr

```
Prelude> foldl (\x carryOver -> carryOver + x) 0 [1 .. 10]  — fold from left to right
55 
Prelude> foldr (\x carryOver -> carryOver + x) 0 [1 .. 10]  — fold from right to left
55
```

####foldl的一种简化表达: fold1

```
Prelude> foldl1 (+) [1 .. 10]
55 
```

Advanced Concepts 
---

###偏应用函数：将多参数的函数拆分为多个只有一个参数的函数


```
-- 发现偏应用
Prelude> let prod x y = x * y
Prelude> :t prod
prod :: Num a => a -> a -> a        -- 看到两个箭头了吗, prod x y其实是通过(prod x ) y实现的
```
```
-- 偏应用：绑定函数的一部分参数
Prelude> let prod x y = x * y
Prelude> let double = prod 2
Prelude> :t double
double :: Num a => a -> a
```

偏应用函数的运算过程称为柯里化

* prod 2 4 实际上计算(prod 2) 4
* 几乎每个Haskell的多参数函数都是柯里化的
 
###惰性求值: 仅仅完成一部分必要的计算


```
-- 可以构造无穷列表
Prelude> take 5 [1..]
[1,2,3,4,5]
```
 
###类型系统
####原生类型

```
Prelude> :set +t
Prelude> 'c'
'c'
it :: Char
Prelude> "abc"
"abc"
it :: [Char]
Prelude> ['a','b','c']
"abc"
it :: [Char]
Prelude> True
True
it :: Bool
```

####自定义类型（利用data关键字定义）


```
./cards-with-show.hs
module Main where
    data Suit = Spades | Hearts deriving  (Show)
    data Rank = Ten | Jack | Queen | King | Ace deriving (Show)
    type Card = (Rank, Suit)
    type Hand = [Card]   
     
    value :: Rank -> Integer
    value Ten = 1
    value Jack = 2
    value Queen = 3
    value King = 4
    value Ace = 5
    
    cardValue :: Card -> Integer
    cardValue (rank, suit) = value rank
```


注：deriving用于函数的继承，代码段中继承了show函数用于在控制台中显示自定义数据类型Suit和Rank


```
Prelude> :load cards-with-show.hs
[1 of 1] Compiling Main             ( cards-with-show.hs, interpreted )
Ok, modules loaded: Main.
*Main> Hearts
Spades
it :: Suit
*Main> Ten
Ten
it :: Rank
*Main> cardValue (Ten, Hearts)
1
```

####类型模板 -> 实现函数的多态以及数据类型的多态

```
./type_template.hs
module Main where
    backwards :: [a] -> [a]
    backwards [] = []
    backwards (h:t) = backwards t ++ [h]
```


####自定义类型模板

```
./userdefine_type_template.hs
module Main where
    data Triplet a = Trio a a a deriving (Show)
```

```
*Main> :load userdefine_type_template.hs
[1 of 1] Compiling Main             ( userdefine_type_template.hs, interpreted )
Ok, modules loaded: Main.
*Main> :t Trio 'a' 'b' 'c'
Trio 'a' 'b' 'c' :: Triplet Char
```

注：Triplet: 类型构造器，Trio: 数据构造器

####自定义递归类型

```
./tree_depth.hs
module Main where
    data Tree a = Children [Tree a] | Leaf a deriving (Show)

    -- define a function to calculate the depth of a tree
    depth (Leaf _) = 1
    depth (Children c) = 1 + maximum (map depth c)
```

```
*Main> :load tree_depth.hs
[1 of 1] Compiling Main             ( tree_depth.hs, interpreted )
Ok, modules loaded: Main.
*Main> let tree = Children[Leaf 1, Children [Leaf 2, Leaf 3]]
*Main> tree
Children [Leaf 1,Children [Leaf 2,Leaf 3]]
*Main> depth tree
3
```

####类

* 为了便于实现函数的继承、重载、多态
* 不同于面向对象中的Class：对象是类型，不涉及数据

```
-- 内置的Eq类，实现了相等判断
class Eq a where
    (==), (/=) :: a -> a -> Bool

    x /= y  =  not (x == y)
    x == y  =  not (x /= y)
```

![Class Hierarchy in Haskell](/img/haskell-class-hierarchy.png)

Monad
---

* 本质上，一个Monad是一个函数组合
* 以特定属性的方式组合函数替代原来的嵌套调用，
* 一个monad = 类型容器 + return函数 + >>==bind函数

用途:

* 可以用于模拟程序的状态，从而实现用纯函数式较难实现的事情，比如IO
* 基于moand实现的do语法可以支持命令式风格的编程 
* Maybe monad可以用来进行错误处理


###Example 1：醉汉问题
####嵌套方式实现

```
./drunken-pirate-without-monad.hs
module Main where
    stagger :: (Num t) => t -> t
    stagger d = d + 2
    crawl d = d + 1
    — 嵌套方式实现
    treasureMap d = crawl ( stagger ( stagger d ) )

*Main> treasureMap 0
5
it :: Num a => a
```


####利用Monad实现

```
./drunken-pirate-monad.hs
module Main where
    data Position t = Position t deriving (Show)   -- 构造一个容器让它来持有一个函数
    stagger (Position d) = Position (d + 2)
    crawl (Position d) = Position (d + 1)

    rtn x = x          -- rtn函数将函数包装到monad中，内置的monad函数使用return
    x >>== f = f x     -- >>==函数负责将函数从monad中解包，内置的monad函数使用>>=
    
    -- 利用monad以函数组合的方式实现
    treasureMap pos = pos >>==
                      stagger >>==
                      stagger >>==
                      crawl >>==
                      rtn
```

```
*Main> treasureMap (Position 0)
Position 5
it :: Num t => Position t
```

###Example 2: 利用do实现I/O monad

```
 ./io-monad.hs
module Main where
    tryIo = do putStr "Enter your name: ";
                line <- getLine;
                let { backwards = reverse line };
                return ("Hello, Your name backwards is " ++ backwards)
```

```
Prelude> :load io-monad.hs
[1 of 1] Compiling Main             ( io-monad.hs, interpreted )
Ok, modules loaded: Main.
*Main> tryIo
Enter your name: abc
"Hello, Your name backwards is cba"
it :: [Char]
```

Reference
---

1. 《七天七语言》，<http://book.douban.com/subject/10555435/>