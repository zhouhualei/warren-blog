title: 'Metaprogramming Ruby, Part 2: Object model and Method in Ruby'
date: 2015-08-30 11:09:11
category: Metaprogramming Ruby
tags: [Ruby,Metaprogramming,Book,Object Model, Method]
---
##说在前面
这篇文章与这个系列的开篇文章隔了很久了，一直也没有能够整理出来，今天终于搞定一篇，希望尽早完成这个系列吧。上篇比较宏观地介绍了Ruby的元编程，从这篇开始，我们将进入Ruby的世界，探索哪些元编程特性。我们会先来介绍Ruby的对象模型和方法，对象模型是整个Ruby语言的基础，也为元编程带来了巨大的灵活性。而Ruby中的方法在对象模型的基础上提供了强大的动态操纵的能力，能够方便地进行元编程。<!--more-->

##Object Model

先来看一张Ruby对象模型的图

![Object Model in Ruby](/img/ruby-object-model.jpeg)

Note:
 - BasicObject类是Ruby类体系结构的根节点
 - Object类是所有类的默认superclass
 - 关于类为什么可以调用class方法，Class的superclass为什么是Module? 这些问题，可以参考另一篇文章《Ruby中那些不太容易理解的特性》

###Module in Object Model
```ruby
 # 查看祖先链
 2.0.0-p247 :001 > String.ancestors
 => [String, Comparable, Object, Kernel, BasicObject]
```
祖先链中Kernel是一个模块，为什么出现在这？Kernel其实是Object中include进来的一个Module，而Ruby底层会将引入的Module封装成一个匿名类插入到包含它的类的上方。

关于Kernel模块，值得一提的是，RubyGem就是在Kernel模块中定义了gem()方法，只要require这个包之后就能在任何地方使用这个方法了，还有proc和lambda方法也定义在Kernel模块中。

###Open Class: 可以用来增强Ruby或者框架、类库提供的类4. 
```ruby
> cat object_model.rb
# 扩展String类
class String
  def to_alphanumeric
    gsub /[^\w\s]/, ''
  end
end
2.0.0-p247 :001 > require './object_model.rb'
 => true 
2.0.0-p247 :004 > "#hello, *Metaprogrammming".to_alphanumeric
 => "hello Metaprogrammming"
```

###Namespace using Module: 可以用来防止命名冲突

```ruby
> cat namespace_example.rb
# 利用module创建namespace
module NamespaceExample
  class String
    def length
      100
    end
  end
end

2.0.0-p247 :004 > String.new.length
=> 0
2.0.0-p247 :004 > NamespaceExample::String.new.length
=> 100
```

##Method in Ruby
###方法的查找与执行
概念

     . Receiver: 方法所在的对象
     . Ancestors: 从Receiver对象所属的类开始到其父类自下而上的链条，以BasicObject为终点，其中也包括模块

- 方法查找就是从Receiver(接收者)开始沿着Ancestors(祖先链)查找，直到找到对应的方法，然后执行该方法。如果没有在Ancestors上找到对应的方法，解释器则会调用Kernel#method_missing()方法，并由它抛出NoMethodError。

- self关键字表示当前对象，当一个方法被调用时，self就对应了receiver。

###方法的动态操纵
利用方法的动态操纵能力可以避免重复代码，这些动态操纵的技术包括：

1. Dynamic Dispatch
2. Dynamic Method
3. Ghost method
4. Dynamic Proxies

####方法的动态调用(利用Dynamic Dispatch技术)
Ruby方法调用的本质是向Receiver发送消息
```ruby
> cat send_message.rb
# 利用send方法进行方法调用
class SendMessage
  def my_method(arg)
    puts arg * 5
  end
end

obj = SendMessage.new
obj.my_method(2)
obj.send(:my_method, 2) 
```
Dynamic Dispatch技术就利用了send方法，将方法名也作为参数，动态确定方法名，从而实现方法的动态调用。

```ruby
# 实例：Test::Unit
method_names = public_instance_methods(true)
tests = method_names.delete_if {|method_name| method_name !~ /^test./}
```

####方法的动态定义(利用Dynamic Method技术)

```ruby
> cat dynamic_method.rb
# 利用Module#define_method()在运行时进行方法定义
class DynamicMethod
  define_method :my_method do |my_arg|
    my_arg * 3
  end
end

puts DynamicMethod.new.my_method(2)
```

####创建幽灵方法(在method_missing内定义)
当无法找到调用的方法时，将会调用self的method_missing方法，可以利用这个特性创建一些Ghost method(幽灵方法)，这些方法并不真正存在，但对用户来说，跟真实存在的方法没有区别。
```ruby
> cat ghost_method.rb
# 在method_missing中创建幽灵方法
class GhostMethod
  def initialize
    @attributes = {}
  end

  def method_missing(name, *args)
    attribute = name.to_s
    if attribute =~ /=$/
      @attributes[attribute.chop] = args[0]
    else
      @attributes[attribute]
    end
  end
end

user = GhostMethod.new
user.name = "Warren"
user.job = "Programmer"
puts user.name
puts user.job
```

####方法的转发(利用Dynamic Proxies技术创建封装对象，来封装另一个对象、Web服务或者其它语言代码)
```ruby
> cat http_wrapper.rb
# 在method_missing中进行方法的转发
class HttpWrapper
  def request(method, *params)
    respose = XmlSimple.xml_in(http_get(request_url(method, params)))
    rails response[‘err’][‘msg’] if response[’stat’] != ‘ok'
    response
  end

  def method_missing(method_id, *params)
    request(mehtod_id.id2name.gsub(/_/, ‘.’), params[0])     # 利用幽灵方法构造HTTP请求并转发给Web Service
  end
end
```

##Conclusion
这里只是罗列了几个基本的元编程技术，将这些技术组合起来能够有效地消除重复代码。你是不是已经领略到了Ruby的神奇了？这还没结束下，期待下一篇吧。

##Reference
1. [《Ruby元编程》](http://book.douban.com/subject/7056800/)


Have Fun!