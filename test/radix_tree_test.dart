import 'dart:math' show Random;

import 'package:radix_tree/radix_tree.dart';
import 'package:test/test.dart';

void main() {
  group('Test RadixTree', () {
    test('Largest Prefix', () {
      expect(largest_prefix_length('abcdefg'.split(""), 'abcdexyz'.split("")), equals(5));
      expect(largest_prefix_length('abcdefg'.split(""), 'abcxyz'.split("")), equals(3));
      expect(largest_prefix_length('abcdefg'.split(""), 'abctuvxyz'.split("")), equals(3));
      expect(largest_prefix_length('abcdefg'.split(""), ''.split("")), equals(0));
      expect(largest_prefix_length(''.split(""), 'abcdexyz'.split("")), equals(0));
      expect(largest_prefix_length('xyz'.split(""), 'abcxyz'.split("")), equals(0));
    });
    test('Empty Tree', () {
      expect(make_radix_tree<int>(), isEmpty);
    });
    test('Single Insertion', () {
      final tree = make_radix_tree<int>();
      tree['test'] = 1;
      expect(tree, isNotEmpty);
      expect(tree, hasLength(equals(1)));
      expect(tree, contains('test'));
    });
    test('Multiple Insertions', () {
      final tree = make_radix_tree<int>();
      tree['test'] = 1;
      tree['tent'] = 2;
      tree['tank'] = 3;
      tree['rest'] = 4;
      expect(tree, hasLength(equals(4)));
      expect(tree, containsPair('test', equals(1)));
      expect(tree, containsPair('tent', equals(2)));
      expect(tree, containsPair('tank', equals(3)));
      expect(tree, containsPair('rest', equals(4)));
    });
    test('Multiple Insertions Of The Same Key', () {
      final tree = make_radix_tree<int>();
      tree['test'] = 1;
      tree['tent'] = 2;
      tree['tank'] = 3;
      tree['rest'] = 4;
      expect(tree, hasLength(4));
      expect(tree, containsPair('test', equals(1)));
      expect(tree, containsPair('tent', equals(2)));
      expect(tree, containsPair('tank', equals(3)));
      expect(tree, containsPair('rest', equals(4)));
      tree['test'] = 9;
      expect(tree, hasLength(equals(4)));
      expect(tree, containsPair('test', 9));
      expect(tree, containsPair('tent', 2));
      expect(tree, containsPair('tank', 3));
      expect(tree, containsPair('rest', 4));
    });
    test('Prefix Fetch', () {
      final tree = make_radix_tree<int>();
      tree['test'] = 1;
      tree['tent'] = 2;
      tree['rest'] = 3;
      tree['tank'] = 4;
      expect(tree, hasLength(equals(4)));
      expect(tree.getValuesWithPrefix(''), containsAll(tree.values));
      expect(tree.getValuesWithPrefix('t'), containsAll(const <int>[1, 2, 4]));
      expect(tree.getValuesWithPrefix('te'), containsAll(const <int>[1, 2]));
      expect(tree.getValuesWithPrefix('asd'), containsAll(const <int>[]));
    });
    test('operator[] Fetch', () {
      final tree = make_radix_tree<int>();
      tree['tes'] = 0;
      tree['test'] = 1;
      tree['tent'] = 2;
      tree['rest'] = 3;
      tree['tank'] = 4;
      tree['tan'] = 5;
      expect(tree, hasLength(equals(6)));
      expect(tree['tes'], equals(0));
      expect(tree['test'], equals(1));
      expect(tree['tent'], equals(2));
      expect(tree['rest'], equals(3));
      expect(tree['tank'], equals(4));
      expect(tree['tan'], equals(5));
      expect(tree[''], isNull);
      expect(tree['t'], isNull);
      expect(tree['te'], isNull);
      expect(tree['tanke'], isNull);
      expect(tree['asd'], isNull);
    });
    test('Contains Key', () {
      final tree = make_radix_tree<int>();
      tree['tes'] = 0;
      tree['test'] = 1;
      tree['tent'] = 2;
      tree['rest'] = 3;
      tree['tank'] = 4;
      tree['tan'] = 5;
      expect(tree, hasLength(equals(6)));
      expect(() => tree.containsKey(null), throwsA(isA<TypeError>()));
      expect(tree, contains('tes'));
      expect(tree, contains('test'));
      expect(tree, contains('tent'));
      expect(tree, contains('rest'));
      expect(tree, contains('tank'));
      expect(tree, contains('tan'));
      expect(tree, isNot(contains('')));
      expect(tree, isNot(contains('t')));
      expect(tree, isNot(contains('te')));
      expect(tree, isNot(contains('tanke')));
      expect(tree, isNot(contains('asd')));
    });
    test('Contains Value', () {
      final tree = make_radix_tree<int>();
      tree[''] = 0;
      tree['test'] = 1;
      tree['tent'] = 2;
      tree['rest'] = 3;
      tree['tank'] = 4;
      expect(tree, hasLength(equals(5)));
      expect(tree, isNot(containsValue(null)));
      expect(tree, containsValue(0));
      expect(tree, containsValue(1));
      expect(tree, containsValue(2));
      expect(tree, containsValue(3));
      expect(tree, containsValue(4));
      expect(tree, isNot(containsValue(5)));
      expect(tree, isNot(containsValue('test')));
    });
    test('Spook', () {
      final tree = make_radix_tree<int>();
      tree['pook'] = 1;
      tree['spook'] = 2;
      expect(tree, hasLength(equals(2)));
      expect(tree.keys, containsAll(<String>['pook', 'spook']));
    });
    test('Removal', () {
      final tree = make_radix_tree<int>();
      tree['test'] = 1;
      tree['tent'] = 2;
      tree['tank'] = 3;
      expect(tree, hasLength(equals(3)));
      expect(tree, contains('tent'));
      tree.remove('key');
      expect(tree, hasLength(equals(3)));
      expect(tree, contains('tent'));
      tree.remove('tent');
      expect(tree, hasLength(equals(2)));
      expect(tree, containsPair('test', equals(1)));
      expect(tree, isNot(contains('tent')));
      expect(tree, containsPair('tank', equals(3)));
    });
    test('Many Insertions', () {
      final tree = make_radix_tree<BigInt>();
      const hex = '0123456789ABCDEF';
      final random = Random();
      final big_ints = <BigInt>{};
      var i = 100 + random.nextInt(400);
      while (i > 0) {
        final big_int = BigInt.parse(
          List<String>.generate(
            20,
            (final index) => hex[random.nextInt(0x10)],
          ).join(),
          radix: 0x10,
        );
        if (!big_ints.contains(big_int)) {
          big_ints.add(big_int);
          tree[big_int.toRadixString(0x10)] = big_int;
        }
        i -= 1;
      }
      expect(tree, hasLength(equals(big_ints.length)));
      for (final big_int in big_ints) {
        expect(tree, containsPair(big_int.toRadixString(0x10), equals(big_int)));
      }
      expect(tree.values, containsAll(big_ints));
    });
  });
}
