title: 4 ways to implement LRUCache in Java
date: 2015-04-19 23:26:06
category: programming
tags: [java, cache]
---

### 说在前面
这两天在LeetCode上写一道LRUCache的题，题不难，用HashMap加双向链表提交通过之后，尝试用其它更简洁的方式进行实现，本文将这些方法一一列出，以供大家参考。<!--more-->

### 1. HashMap + 双向链表
```java
package me.warren.leetcode;

import java.util.HashMap;
import java.util.Map;

/**
 * Created by warzhou1 on 4/18/15.
 * Problem 146
 */
public class LRUCache {

    private Map hash;
    private int capacity;

    private LinkedNode head;
    private LinkedNode tail;

    public LRUCache(int capacity) {
        this.hash = new HashMap<Integer, LinkedNode>(capacity);
        this.head = null;
        this.tail = null;
        this.capacity = capacity;
    }

    public int get(int key) {
        LinkedNode node = (LinkedNode) this.hash.get(key);
        if (node != null) {
            moveToHead(node);

            return node.value;
        } else {
            return -1;
        }
    }

    public void set(int key, int value) {
        if (size() > 0 && size() == capacity && this.hash.get(key) == null) {
            // remove the tail node
            this.hash.remove(this.tail.key);
            this.tail = this.tail.prev;
        }

        if (size() > 0) {
            if (this.hash.get(key) == null) {
                LinkedNode newNode = new LinkedNode(key, value);
                this.hash.put(key, newNode);
                addToHead(newNode);
            } else {
                LinkedNode oldNode = (LinkedNode) this.hash.get(key);
                oldNode.value = value;
                moveToHead(oldNode);
            }
        } else {
            LinkedNode newNode = new LinkedNode(key, value);
            this.head = newNode;
            this.tail = newNode;
            this.hash.put(key, newNode);
        }
    }

    private int size() {
        return this.hash.size();
    }

    private void addToHead(LinkedNode node) {
        node.next = this.head;
        this.head.prev = node;
        this.head = node;
    }

    private void moveToHead(LinkedNode node) {
        if (node != this.head) {

            // remove from old position
            node.prev.next = node.next;
            if (node == this.tail) {
                this.tail = node.prev;
            } else {
                node.next.prev = node.prev;
            }

            addToHead(node);
        }
    }

}

class LinkedNode {
    int key;
    int value;
    LinkedNode prev;
    LinkedNode next;

    public LinkedNode(int key, int value) {
        this.key = key;
        this.value = value;
        this.prev = null;
        this.next = null;
    }
}

```

### 2. LinkedHashMap
```java
package me.warren.leetcode;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Created by warzhou1 on 4/19/15.
 * Problem 146
 * Make use of LinkedHashMap to implement a LRUCache
 */
public class LRUCacheByLinkedHashMap {

    private Map linkedMap;

    public LRUCacheByLinkedHashMap(final int capacity) {
        linkedMap = new LinkedHashMap<Integer, Integer>(capacity, 1, true) {
            protected boolean removeEldestEntry (Map.Entry<Integer, Integer> eldest){
                return size() > capacity;
            }
        };
    }

    public int get(int key) {
        Object value = linkedMap.get(key);
        if (value == null) {
            return -1;
        }
        return (Integer)value;
    }

    public void set(int key, int value) {
        linkedMap.put(key, value);
    }

}
```


### 3. LRUMap
```java
package me.warren.leetcode;

import org.apache.commons.collections4.map.LRUMap;

/**
 * Created by warzhou1 on 4/19/15.
 * Problem 146
 * Make use of LRUMap to implement a LRUCache
 */
public class LRUCacheByLRUMap {

    private LRUMap map;

    public LRUCacheByLRUMap(int capacity) {
        map = new LRUMap(capacity);
    }

    public int get(int key) {
        Object value = map.get(key);
        if (value == null) {
            return -1;
        }
        return (Integer) value;
    }

    public void set(int key, int value) {
        map.put(key, value);
    }

}
```


### 4. Guava CacheBuilder
```java
package me.warren.leetcode;

import com.google.common.cache.Cache;
import com.google.common.cache.CacheBuilder;

/**
 * Created by warzhou1 on 4/19/15.
 * Problem 146
 * Make use of Guava CacheBuilder to implement a LRUCache
 */
public class LRUCacheByGuava {

    private Cache<Integer, Integer> cache;

    public LRUCacheByGuava(int capacity) {
        cache = CacheBuilder.newBuilder().maximumSize(capacity).build();
    }

    public int get(int key) throws Exception {
        Object value = cache.getIfPresent(key);
        if (value == null) {
            return -1;
        }
        return (Integer) value;
    }

    public void set(int key, int value) {
        cache.put(key, value);
    }

}
```

Have Fun!

<center>
![卧舟杂谈](/img/58a1d13a6c923c68fc000003.png)
订阅我的微信公众号，您将即时收到新博客提醒！
</center>
