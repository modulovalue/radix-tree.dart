import 'dart:collection' show MapBase;
import 'dart:math' show min;

// region factory
RadixTree<String, T> make_radix_tree<T>() {
  // Put the value with the given key from
  // the subtree rooted at the given node.
  void put_value(
    final RadixTreeNode<String, T> node,
    final String key,
    final T? value,
  ) {
    final largest_prefix = largest_prefix_length(key.split(""), node.prefix.split(""));
    if (largest_prefix == node.prefix.length && largest_prefix == key.length) {
      // Exact match, update the value here.
      node.value = value;
    } else if (largest_prefix == 0 ||
        (largest_prefix < key.length && largest_prefix == node.prefix.length)) {
      // Key we're looking for shares no common prefix (e.g. at the root), OR
      // Key we're looking for subsumes this node's string.
      final left_over_key = key.substring(largest_prefix);
      bool found = false;
      // Try to find a child node that continues matching the remainder.
      for (final child in node.children) {
        if (child.prefix[0] == left_over_key[0]) {
          found = true;
          put_value(child, left_over_key, value);
          break;
        }
      }
      // Otherwise add the remainder as a child of this node.
      if (!found) {
        final new_node = RadixTreeNode<String, T>(
          prefix: left_over_key,
          value: value,
          children: {},
        );
        node.children.add(new_node);
      }
    } else {
      // case largestPrefix < node.prefix.length:
      // Key we're looking for shares a non-empty subset of this node's string.
      final left_over_prefix = node.prefix.substring(largest_prefix);
      final newNode = RadixTreeNode<String, T>(
        prefix: left_over_prefix,
        value: node.value,
        children: node.children.toSet(),
      );
      node
        ..prefix = node.prefix.substring(0, largest_prefix)
        ..children.clear()
        ..children.add(newNode);
      if (largest_prefix == key.length) {
        node.value = value;
      } else {
        final leftOverKey = key.substring(largest_prefix);
        final keyNode = RadixTreeNode<String, T>(
          prefix: leftOverKey,
          value: value,
          children: {},
        );
        node
          ..children.add(keyNode)
          ..value = null;
      }
    }
  }

  // Remove the value with the given key from the
  // subtree rooted at the given node.
  T? remove_value(
    final RadixTreeNode<String, T> node,
    final String key,
  ) {
    T? result;
    final childrend = node.children.toList();
    int i = 0;
    while (i < childrend.length) {
      final child = childrend[i];
      final largestPrefix = largest_prefix_length(
        key.split(""),
        child.prefix.split(""),
      );
      if (largestPrefix == child.prefix.length && largestPrefix == key.length) {
        if (child.children.isEmpty) {
          result = child.value;
          node.children.remove(child);
        } else if (child.hasValue) {
          result = child.value;
          child.value = null;
          if (child.children.length == 1) {
            final subchild = child.children.first;
            child
              ..prefix = child.prefix + subchild.prefix
              ..value = subchild.value
              ..children.clear();
          }
          break;
        }
      } else if (largestPrefix > 0 && largestPrefix < key.length) {
        final leftoverKey = key.substring(largestPrefix);
        result = remove_value(child, leftoverKey);
        break;
      }
      i += 1;
    }
    return result;
  }

  return RadixTree(
    key_length: (final a) => a.length,
    key_get: (final a, final b) => a[b],
    sum: (final a, final b) => a + b,
    starts_with: (final a, final b) => a.startsWith(b),
    start: "",
    root: RadixTreeNode<String, T>(
      prefix: "",
      value: null,
      children: {},
    ),
    removeValue: remove_value,
    putValue: put_value,
  );
}
// endregion

// region impl
class RadixTree<K, T> extends MapBase<K, T?> {
  // region prelude
  final RadixTreeNode<K, T> root;
  final K start;
  final int Function(K) key_length;
  final K Function(K, int) key_get;
  final K Function(K, K) sum;
  final bool Function(K, K) starts_with;
  final void Function(RadixTreeNode<K, T> node, K key, T? value) putValue;
  final T? Function(RadixTreeNode<K, T> node, K key) removeValue;

  RadixTree({
    required this.start,
    required this.key_length,
    required this.key_get,
    required this.starts_with,
    required this.sum,
    required this.putValue,
    required this.removeValue,
    required this.root,
  });
  // endregion

  // region impl
  @override
  Iterable<MapEntry<K, T?>> get entries {
    final entries = <MapEntry<K, T?>>[];
    void visitor(final K key, final T? value) {
      entries.add(MapEntry<K, T?>(key, value));
    }

    visitRoot(visitor);
    return entries;
  }

  @override
  bool get isEmpty {
    return root.children.isEmpty;
  }

  @override
  bool get isNotEmpty {
    return root.children.isNotEmpty;
  }

  @override
  Iterable<K> get keys {
    final keys = <K>[];
    void visitor(final K key, final T? value) {
      keys.add(key);
    }

    visitRoot(visitor);
    return keys;
  }

  @override
  int get length {
    int count = 0;
    void visitor(final K key, final T? value) {
      count += 1;
    }

    visitRoot(visitor);
    return count;
  }

  @override
  Iterable<T?> get values {
    final values = <T?>[];
    void visitor(final K key, final T? value) {
      values.add(value);
    }

    visitRoot(visitor);
    return values;
  }

  @override
  T? operator [](
    final Object? key,
  ) {
    if (key is K) {
      T? found;
      void visitor(final K k, final T? v) {
        if (k == key) {
          found = v;
        }
      }

      visitKey(root, key, start, visitor);
      return found;
    } else {
      throw TypeError();
    }
  }

  @override
  void operator []=(final K key, final T? value) {
    putValue(root, key, value);
  }

  @override
  void clear() {
    root.children.clear();
  }

  @override
  bool containsKey(
    final Object? key,
  ) {
    if (key is K) {
      bool found = false;
      void visitor(final K keyToCheck, final T? value) {
        if (keyToCheck == key) {
          found = true;
        }
      }
      visitKey(root, key, start, visitor);
      return found;
    } else {
      throw TypeError();
    }
  }

  @override
  bool containsValue(
    final Object? value,
  ) {
    bool found = false;
    void visit(final K k, final T? v) {
      if (value == v) {
        found = true;
      }
    }

    visitRoot(visit);
    return found;
  }

  @override
  T? remove(
    final Object? key,
  ) {
    if (key is K) {
      if (key_length(key) == 0) {
        final value = root.value;
        root.value = null;
        return value;
      }
      return removeValue(root, key);
    } else {
      throw TypeError();
    }
  }
  // endregion

  // region additional
  /// Gets a list of entries whose associated keys have the given prefix.
  List<MapEntry<K, T?>> getEntriesWithPrefix(
    final K prefix,
  ) {
    final entries = <MapEntry<K, T?>>[];
    void visitor(final K key, final T? value) {
      entries.add(MapEntry<K, T?>(key, value));
    }

    visitRootPrefixed(visitor, prefix);
    return entries;
  }

  /// Gets a list of keys with the given prefix.
  List<K> getKeysWithPrefix(
    final K prefix,
  ) {
    final keys = <K>[];
    void visitor(final K key, final T? value) {
      keys.add(key);
    }

    visitRootPrefixed(visitor, prefix);
    return keys;
  }

  /// Gets a list of values whose associated keys have the given prefix.
  List<T> getValuesWithPrefix(
    final K prefix,
  ) {
    final values = <T>[];
    void visitor(final K key, final T? value) {
      if (value != null) {
        values.add(value);
      }
    }
    visitRootPrefixed(visitor, prefix);
    return values;
  }
  // endregion

  // region visit
  /// Visits the given node of this tree with the given key and visitor.
  void visitKey(
    final RadixTreeNode<K, T> node,
    final K key,
    final K prefix,
    final void Function(K key, T? value) visitor,
  ) {
    if (node.hasValue && prefix == key) {
      visitor(prefix, node.value);
      return;
    } else {
      final prefixLength = key_length(prefix);
      if (key_length(key) > prefixLength) {
        // Search the children only if there's more key remaining.
        // Unfortunately this is O(|your_alphabet|)
        for (final child in node.children) {
          if (key_get(child.prefix, 0) == key_get(key, prefixLength)) {
            return visitKey(child, key, sum(prefix, child.prefix), visitor);
          }
        }
      }
    }
  }

  /// Visits the given node of this tree with the given prefix and visitor.
  ///
  /// Also, recursively visits the left/right subtrees of this node.
  void visit(
    final RadixTreeNode<K, T> node,
    final K prefix_vllowed,
    final K prefix,
    final void Function(K key, T? value) visitor,
  ) {
    if (node.hasValue && starts_with(prefix, prefix_vllowed)) {
      visitor(prefix, node.value);
    }
    final prefixLength = key_length(prefix);
    for (final child in node.children) {
      if (key_length(prefix_vllowed) <= prefixLength ||
          key_get(child.prefix, 0) == key_get(prefix_vllowed, prefixLength)) {
        visit(child, prefix_vllowed, sum(prefix, child.prefix), visitor);
      }
    }
  }

  void visitRoot(
    final void Function(K key, T? value) visitor,
  ) {
    // Note that the tree will be traversed in lexicographical order.
    visit(root, start, start, visitor);
  }

  /// Traverses this radix tree using the given visitor.
  ///
  /// Only values with the given prefix will be visited. Note that the tree
  /// will be traversed in lexicographical order.
  void visitRootPrefixed(
    final void Function(K key, T? value) visitor,
    final K prefix,
  ) {
    visit(root, prefix, start, visitor);
  }
  // endregion
}

class RadixTreeNode<K, T> {
  // TODO this is not needed
  K prefix;
  T? value;
  final Set<RadixTreeNode<K, T>> children;

  RadixTreeNode({
    required this.prefix,
    required this.value,
    required this.children,
  });

  bool get hasValue {
    return value != null;
  }

  @override
  int get hashCode {
    return prefix.hashCode ^ value.hashCode ^ children.hashCode;
  }

  @override
  bool operator ==(
    final Object other,
  ) {
    return other is RadixTreeNode<K, T> &&
        prefix == other.prefix &&
        value == other.value &&
        children == other.children;
  }
}
// endregion

// region string utils
int largest_prefix_length(
  final List<String> first,
  final List<String> second,
) {
  final common_length = min(first.length, second.length);
  for (int i = 0; i < common_length; i += 1) {
    if (first[i] != second[i]) {
      return i;
    }
  }
  return common_length;
}
// endregion