// ignore_for_file: avoid_print

import 'package:radix_tree/radix_tree.dart';

void main() {
  final tree = make_radix_tree<int>();
  tree['paku'] = 1;
  tree['piku'] = 2;
  tree['pako'] = 3;
  print(tree.keys);
  print(tree.getValuesWithPrefix('p')); // [1, 3, 2]
  print(tree.getValuesWithPrefix('pa')); // [1, 3]
}
