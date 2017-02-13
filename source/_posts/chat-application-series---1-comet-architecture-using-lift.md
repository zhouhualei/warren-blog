title: "Chat Application Series - 1: Comet architecture using Lift"
date: 2014-11-17 02:06:44
category: programming
tags: [chat, web, scala, lift]
---

说在前面
---
最近听了一场聊天系统设计的分享之后，想研究下不同技术架构不同语言组合下的chat application的实现。今天抽空翻出了以前敲过的基于lift的一个实现版本，原来是《Simply Lift》中的一个sample application。lift是由scala编写的web framework，这个版本的实现采用Comet方式通过HTTP连接的保持完成页面的实时刷新。<!--more-->

开发环境
---

- Mac OSX 10.8.5
- sbt 0.13.1
- scala 2.10.4~~~~~~~~
- intellij 14.0.1 Community Edition

Step By Step
---
安装sbt环境

```zsh
$ brew install sbt
$ sbt --version
```

配置项目骨架插件

```zsh
$ mkdir ~/.sbt/0.13/plugins

$ vim ~/.sbt/0.13/plugins/np.sbt
addSbtPlugin("me.lessis" % "np" % "0.2.0")

$ vim ~/.sbt/0.13/np.sbt
seq(npSettings: _*)
```

新建项目

```
$ mkdir chat-app-liftweb-version
$ cd chat-app-liftweb-version
```

生成项目骨架

```
$ sbt np
```

配置project的dependency

```
$ vim build.sbt

organization := "me.warren"

name := "chat-app-liftweb-version"

version := "1.0"

scalaVersion := "2.10.0"

resolvers ++= Seq("snapshots"     at "http://oss.sonatype.org/content/repositories/snapshots",
                  "releases"      at "http://oss.sonatype.org/content/repositories/releases"
                )

seq(webSettings :_*)

libraryDependencies ++= {
  val liftVersion = "2.5-RC1"
  Seq(
    "net.liftweb"       %% "lift-webkit"        % liftVersion        % "compile",
    "org.eclipse.jetty" % "jetty-webapp" % "8.1.7.v20120910" % "container;provided",
    "org.eclipse.jetty.orbit" % "javax.servlet" % "3.0.0.v201112011016" % "container,compile" artifacts Artifact("javax.servlet", "jar", "jar")
  )
}

```
配置sbt plugin

```
$ vim project/plugins.sbt

addSbtPlugin("com.github.mpeltonen" % "sbt-idea" % "1.6.0")

addSbtPlugin("com.earldouglas" % "xsbt-web-plugin" % "0.7.0")

```

下载scala, sbt plugin和dependency

```
$ sbt update
```

生成Intellij相关的项目文件，便于import到Intellij中进行后续开发

```
$ sbt gen-idea
```

启动jetty，http://localhost:8080/

```
$ sbt ~container:start
```

代码分析
---
详细代码可参考<https://github.com/zhouhualei/chat-app-liftweb-version>，这里只对核心代码做下简单分析。


### _HTML页面_

只有一个主页面，完整路径为src/main/webapp/index.html

```html

<div id="main" class="lift:surround?with=default;at=content">
    <!-- the behavior of the div -->
    <div class="lift:comet?type=Chat">
        Some chat messages
        <ul>
            <li>A message</li>
            <li class="clearable">Another message</li>
            <li class="clearable">A third message</li>
        </ul> </div>
    <div>
        <form class="form.ajax">
            <input class="lift:ChatIn" id="chat_in"/>
            <input type="submit" value="Say Something"/>
        </form>
    </div>
</div>

```

### _聊天表单(ChatIn)_

表单提交时，将内容发送给ChatServer，完整路径为src/main/scala/code/snippet/ChatIn

```scala

package code.snippet

import net.liftweb._
import http._
import js._
import JsCmds._
import JE._

import code.comet.ChatServer

/**
 * A snippet transforms input to output... it transforms * templates to dynamic content. Lift's templates can invoke * snippets and the snippets are resolved in many different * ways including "by convention". The snippet package * has named snippets and those snippets can be classes * that are instantiated when invoked or they can be * objects, singletons. Singletons are useful if there's * no explicit state managed in the snippet.
 */
object ChatIn {

  def render = SHtml.onSubmit(s => {
    ChatServer ! s
    SetValById("chat_in", "")
  })

}

```

### _聊天服务器(ChatServer)_

利用Actor并发模型，同时维护多个clients的服务，当聊天记录发生变化时，通知Chat让其通过Comet方式刷新浏览器页面。完整路径为src/main/scala/code/comet/ChatServer

```scala
package code.comet

import net.liftweb._
import http._
import actor._

/**
 * A singleton that provides chat features to all clients. * It's an Actor so it's thread-safe because only one * message will be processed at once. */
object ChatServer extends LiftActor with ListenerManager {

  private var msgs = Vector("Welcome")

  def createUpdate = msgs

  override def lowPriority = {
    case s: String => msgs :+= s; updateListeners()
  }

}
```

### _聊天记录(Chat)_

负责页面的实时刷新，通过注册ChatServer，当ChatServer收到message时，会得到通知。完整路径为src/main/scala/code/comet/Chat

```scala

package code.comet

import net.liftweb._
import http._
import util._
import Helpers._

/** * The screen real estate on the browser will be represented * by this component. When the component changes on the server * the changes are automatically reflected in the browser. */
class Chat extends CometActor with CometListener{

  private var msgs: Vector[String] = Vector()

  def registerWith = ChatServer

  override def lowPriority = {
    case v: Vector[String] => msgs = v; reRender()
  }

  def render = "li *" #> msgs & ClearClearable
}


```

UI效果
---
![聊天室页面](/img/chat-app-lift-version-ui.png)

Resource
--- 

> 1. Simply Lift, <http://simply.liftweb.net>
> 2. Lift Cookbook, <http://chimera.labs.oreilly.com/books/1234000000030/index.html>

<center>
![卧舟杂谈](/img/58a1d13a6c923c68fc000003.png)
订阅我的微信公众号，您将即时收到新博客提醒！
</center>
