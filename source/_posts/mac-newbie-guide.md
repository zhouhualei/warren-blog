title: Windows转Mac上手指南
date: 2017-02-15 00:44:55
category: Productivity 
tags: [Productivity, Mac, Guide]
---

# 说在前面

这是一篇写给刚从Windows转到Mac的开发人员的文章，因为团队有很多小伙伴在年后换了Mac（三年前公司估计有点穷），环境搭建和使用上有不少问题，所以整理一个列表，也算是我自己在Mac上的最佳时间了吧。

# 一、如何培养Mac思维

## 你需要抛弃:

> - 磁盘分区概念
> - 文件夹整理洁癖（少数重要文件除外）
> - 对GUI应用程序的强依赖
> - 对鼠标的强依赖

## 你需要习惯:

> - 键盘, 触摸板, Command键 
> - 文件搜索
> - 命令行
> - 高效编辑器

<!-- more -->

# 二、常用快捷键
|功能|快捷键|
|-----|----|
|应用切换|Command + Tab, Command + Tab + Shift|
|桌面切换|四指左右滑动|
|打开新窗口|Command + n|
|关闭窗口|Command + w|
|关闭程序|Command + q|
|区域截图保存成文件|Command + Shift + 4|
|区域截图保存到剪贴板|Command + Shift + Ctrl + 4|

**快捷键查询：CheatSheet**
长按Command键，出现当前应用程序的快捷键列表，比如下图为Finder的快捷键列表
![Cheatsheet](/img/58a309c06c923c68fc000008.png)

# 三、自带软件简介

## 文件夹：Finder
> - 自定义工具栏
> - 自定义常用文件夹

## 文件预览：Preview
支持PDF/图片等格式

## 笔记：Notes
支持“笔记本/笔记”两级笔记管理

# 四、第三方软件推荐

## 搜索神器：Alfred
取代系统自带的Spotlight, option + 空格 唤起Alfred搜索框, 这里列举一些重要特性：
> - 根据应用名搜索应用程序
> - 根据文件名搜索文件
> - 打开浏览器搜索
> - 自定义搜索配置
> - 当计算器用
> - 可编程Workflow，收费版

## 终端工具：Iterm2
*主要特性*
> - 颜值更高
> - ⌘ + Click: 打开文件/文件夹/链接
> - ⇧⌘ + d / ⌘ + d: 分屏
> - 配置新Tab页复用前一页的目录
> - 配置多Profile满足编码切换/主机管理等需求

## Shell环境：Zsh + on-my-zsh
Mac下支持的shell:
```shell
$ cat /etc/shells
/bin/bash
/bin/csh
/bin/ksh
/bin/sh
/bin/tcsh
/bin/zsh
```
当然zsh最强大，号称“终极Shell”，当然其配置也非常复杂，好在国外大牛开发oh-my-zsh大大简化了配置过程，并且提供了比如git,brew等插件，以及大量主题。

具体配置我就不多说了，推荐大家看卖桃君的[博文](http://macshuo.com/?p=676)。配置后的界面如下，还是挺炫的。
![zsh效果](/img/58a322386c923c68fc00000b.png)

这里简单罗列最常用的几个特性：
> - git插件：Shell会展示当前目录所在项目对应的branch，者从上图中可以看到。另外，git的命令被简化成gco=’git checkout’、gd=’git diff’、gst=’git status’、g=’git’，习惯了之后非常高效。
> - osx插件：tab增强，前向后向均可补齐
> - 文件后缀与编辑器对应，比如java对应intellij, html对应sublime
> - ssh + 空格 + 两个tab列出所有访问过的主机和用户名
> - 可以省略cd
> - 输入d或者j --stat可以查看所有历史目录

## 应用管理：brew
类似Ubuntu下的apt-get，CentOS下的yum。可以方便的一键安装、卸载、升级各种工具。Mac下安装应用程序建议按以下优先级进行：
> brew > App Store > dmg package

掌握以下几个命令就基本够用了：
```shell
brew search wget
```

安装
```shell
brew install wget
```
列表
```shell
brew list
```

通过brew你可以把git, svn, maven的命令行工具都安装好。

## 文本编辑器：Vim
Vim作为与Emacs齐名的神器，展开说估计能写一本书。这里推荐大家使用吧（也可以考虑用客户端MacVim），掌握Vim你就离戒掉鼠标又近了一步。

## 可视化编辑器：Sublime Text
可视化的文件编辑，基本够用，如果你喜欢折腾，它的package系统也很强大，有大量的插件可以使用。

## Markdown编辑器: MacDown等
markdown对于对经常写文档的人来说是强需求，免费的我推荐用MacDown，当然体验更好的收费版很多人都推荐Ulysses。

## JDK
目前的系统不再自带java6，如果希望运行java6，需要利用安装包手动安装。

获取JDK的Home目录的命令：
```shell
$ /usr/libexec/java_home -v 1.6
```

## IDE: IntelliJ Idea
对于从Eclipse转过来的同学，主要需要理解Project和Module这两个概念，其它的就是熟悉快捷键的问题了。友情提醒，IntelliJ对于内存和CPU的消耗还是挺吓人的。
社区版本开箱即用基本能满足需求，等掌握了快捷键再来研究有什么好用的插件就可以了。

## Finder与Iterm2间互相跳转：cdto

安装过程：在Finder中选中cdto应用程序，按住Command键并拖动至工具栏即可
![cdto-install](/img/58a31a116c923c68fc00000a.gif)

安装后的效果：利用open或者Command + Click从Finder跳转到Iterm2，利用cd2从Iterm2跳转到Finder
![Finder-Iterm2](/img/58a3064e6c923c68fc000006.gif)

## Java版本管理：jenv
可以使用jenv为不同的项目设置不同的jdk版本，因为jenv有global和local的概念,local配置会覆盖全局配置。jenv也可以使用brew进行安装。

查看所有jdk
```shell
$ jenv versions
  system
* 1.6 (set by /Users/warren.zhl/.java-version)
  1.6.0.65
  1.8
  1.8.0.102
  oracle64-1.6.0.65
  oracle64-1.8.0.102
```
使用以下命令就可以设置局部jdk版本：
```shell
$ jenv local 1.8
$ jenv versions
  system
  1.6
  1.6.0.65
* 1.8 (set by /Users/warren.zhl/projects/alipay-projects/sofa/demo/.java-version)
  1.8.0.102
  oracle64-1.6.0.65
  oracle64-1.8.0.102
```
其实它是通过本地的.java-version文件实现的
```shell
$ cat .java-version
1.8
```

# 五、值得阅读的博客/书籍
1. [终极 Shell](http://macshuo.com/?p=676)
2. [神兵利器——Alfred](http://macshuo.com/?p=625)
3. [MacTalk](http://macshuo.com/)
4. [《MacTalk 人生元编程》](https://book.douban.com/subject/25826578/)

---

希望Mac能够给你带来愉悦!

---

<center>
![卧舟杂谈](/img/58a1d13a6c923c68fc000003.png)
订阅我的微信公众号，您将即时收到新博客提醒！
</center>

