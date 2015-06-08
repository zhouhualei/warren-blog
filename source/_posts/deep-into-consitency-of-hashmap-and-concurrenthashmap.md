title: "Deep in JUC, Part 1: 深究HashMap以及ConcurrentHashMap的一致性问题"
date: 2015-06-08 07:39:15
category: Deep in JUC
tags: [java,juc,Book]
---


##HashMap与ConcurrentHashMap
众所周知，HashMap无法做到线程安全，在某些特定的场景下甚至会出现死循环的情况。而ConcurrentHashMap是HashMap的并发版本，它能够做到线程安全。<!--more-->



>ConcurrentHashMap返回的迭代器具有弱一致性（weakly consistent），而并非“及时失败”。弱一致性的迭代器可以容忍并发的修改...
                                                                                                                                												                             ——《Java并发编程实战》


##迭代器的一致性问题

Java容器类的迭代操作最标准的方式就是使用Iterator，在并发修改的情况下，Iterator的一致性问题就暴露出来了。这种情况下，强一致性的表现就是”及时失败“，抛出大家并不陌生的ConcurrentModificationException。如果只支持弱一致性呢，它就会忽略这个不一致性，允许容器在迭代期间被并发修改。


##强一致性是如何实现的

HashMap的强一致性是通过引入计数器实现的。

```java
    /**
     * The number of times this HashMap has been structurally modified
     * Structural modifications are those that change the number of mappings in
     * the HashMap or otherwise modify its internal structure (e.g.,
     * rehash).  This field is used to make iterators on Collection-views of
     * the HashMap fail-fast.  (See ConcurrentModificationException).
     */
    transient int modCount;
```

通过引入一个名为modCount的计数器，当有任何修改容器的操作发生后，这个计数器就会自增。以put方法为例：
```java
    public V put(K key, V value) {
        if (table == EMPTY_TABLE) {
            inflateTable(threshold);
        }
        if (key == null)
            return putForNullKey(value);
        int hash = hash(key);
        int i = indexFor(hash, table.length);
        for (Entry<K,V> e = table[i]; e != null; e = e.next) {
            Object k;
            if (e.hash == hash && ((k = e.key) == key || key.equals(k))) {
                V oldValue = e.value;
                e.value = value;
                e.recordAccess(this);
                return oldValue;
            }
        }

        modCount++;
        addEntry(hash, key, value, i);
        return null;
    }
```

然后，我们再来看看HashMap中的迭代操作，以keySet()为例, 从代码中可以发现它所返回的迭代器类型为HashIterator，在HashIterator的初始化中，会将modCount赋值给expectedModCount, 如果在随后的迭代操作中发现两者不一致就会立即抛出ConcurrentModificationException，这也是所谓的fast-fail。

```java
    public Set<K> keySet() {
        Set<K> ks = keySet;
        return (ks != null ? ks : (keySet = new KeySet()));
    }

    private final class KeySet extends AbstractSet<K> {
        public Iterator<K> iterator() {
            return newKeyIterator();
        }
        public int size() {
            return size;
        }
        public boolean contains(Object o) {
            return containsKey(o);
        }
        public boolean remove(Object o) {
            return HashMap.this.removeEntryForKey(o) != null;
        }
        public void clear() {
            HashMap.this.clear();
        }
    }

    Iterator<K> newKeyIterator()   {
        return new KeyIterator();
    }

    private final class KeyIterator extends HashIterator<K> {
        public K next() {
            return nextEntry().getKey();
        }
    }

    private abstract class HashIterator<E> implements Iterator<E> {
        Entry<K,V> next;        // next entry to return
        int expectedModCount;   // For fast-fail
        int index;              // current slot
        Entry<K,V> current;     // current entry

        HashIterator() {
            expectedModCount = modCount;
            if (size > 0) { // advance to first entry
                Entry[] t = table;
                while (index < t.length && (next = t[index++]) == null)
                    ;
            }
        }

        public final boolean hasNext() {
            return next != null;
        }

        final Entry<K,V> nextEntry() {
            if (modCount != expectedModCount)
                throw new ConcurrentModificationException();
            Entry<K,V> e = next;
            if (e == null)
                throw new NoSuchElementException();

            if ((next = e.next) == null) {
                Entry[] t = table;
                while (index < t.length && (next = t[index++]) == null)
                    ;
            }
            current = e;
            return e;
        }

        public void remove() {
            if (current == null)
                throw new IllegalStateException();
            if (modCount != expectedModCount)
                throw new ConcurrentModificationException();
            Object k = current.key;
            current = null;
            HashMap.this.removeEntryForKey(k);
            expectedModCount = modCount;
        }
    }
```


##ConcurrentHash的迭代操作为什么是弱一致性的

同样的，ConcurrentHashMap的keySet()方法最终也是通过HashIterator的迭代器实现，但代码已经发生了变化，它已经不再维护任何计数器，而且代码中也不会再抛出ConcurrentHashMap()，当容器被并发修改时，迭代操作将会继续执行，因此无法保证迭代操作一定能够得到容器中最新的内容。

```java
    abstract class HashIterator {
        int nextSegmentIndex;
        int nextTableIndex;
        HashEntry<K,V>[] currentTable;
        HashEntry<K, V> nextEntry;
        HashEntry<K, V> lastReturned;

        HashIterator() {
            nextSegmentIndex = segments.length - 1;
            nextTableIndex = -1;
            advance();
        }

        final void advance() { … }

        final HashEntry<K,V> nextEntry() {
            HashEntry<K,V> e = nextEntry;
            if (e == null)
                throw new NoSuchElementException();
            lastReturned = e; // cannot assign until after null check
            if ((nextEntry = e.next) == null)
                advance();
            return e;
        }

        public final boolean hasNext() { return nextEntry != null; }
        public final boolean hasMoreElements() { return nextEntry != null; }

        public final void remove() {
            if (lastReturned == null)
                throw new IllegalStateException();
            ConcurrentHashMap.this.remove(lastReturned.key);
            lastReturned = null;
        }
    }
```


##总结

最后，从线程安全性、迭代操作的一致性和性能三个方面分别做一个比较：

![三个维度比较](/img/deep-into-consitency-of-hashmap-and-concurrenthashmap-1.png)


##Reference
1. 《Java并发编程实战》
2.  jdk 1.7.0_45 源代码