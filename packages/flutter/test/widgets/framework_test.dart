// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

typedef ElementRebuildCallback = void Function(StatefulElement element);

class TestState extends State<StatefulWidget> {
  @override
  Widget build(BuildContext context) => null;
}

@optionalTypeArgs
class _MyGlobalObjectKey<T extends State<StatefulWidget>> extends GlobalObjectKey<T> {
  const _MyGlobalObjectKey(Object value) : super(value);
}

void main() {
  testWidgets('UniqueKey control test', (WidgetTester tester) async {
    final Key key = UniqueKey();
    expect(key, hasOneLineDescription);
    expect(key, isNot(equals(UniqueKey())));
  });

  testWidgets('ObjectKey control test', (WidgetTester tester) async {
    final Object a = Object();
    final Object b = Object();
    final Key keyA = ObjectKey(a);
    final Key keyA2 = ObjectKey(a);
    final Key keyB = ObjectKey(b);

    expect(keyA, hasOneLineDescription);
    expect(keyA, equals(keyA2));
    expect(keyA.hashCode, equals(keyA2.hashCode));
    expect(keyA, isNot(equals(keyB)));
  });

  testWidgets('GlobalObjectKey toString test', (WidgetTester tester) async {
    const GlobalObjectKey one = GlobalObjectKey(1);
    const GlobalObjectKey<TestState> two = GlobalObjectKey<TestState>(2);
    const GlobalObjectKey three = _MyGlobalObjectKey(3);
    const GlobalObjectKey<TestState> four = _MyGlobalObjectKey<TestState>(4);

    expect(one.toString(), equals('[GlobalObjectKey ${describeIdentity(1)}]'));
    expect(two.toString(), equals('[GlobalObjectKey<TestState> ${describeIdentity(2)}]'));
    expect(three.toString(), equals('[_MyGlobalObjectKey ${describeIdentity(3)}]'));
    expect(four.toString(), equals('[_MyGlobalObjectKey<TestState> ${describeIdentity(4)}]'));
  });

  testWidgets('GlobalObjectKey control test', (WidgetTester tester) async {
    final Object a = Object();
    final Object b = Object();
    final Key keyA = GlobalObjectKey(a);
    final Key keyA2 = GlobalObjectKey(a);
    final Key keyB = GlobalObjectKey(b);

    expect(keyA, hasOneLineDescription);
    expect(keyA, equals(keyA2));
    expect(keyA.hashCode, equals(keyA2.hashCode));
    expect(keyA, isNot(equals(keyB)));
  });

  testWidgets('GlobalKey correct case 1 - can move global key from container widget to layoutbuilder', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'correct');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(
          key: const ValueKey<int>(1),
          child: SizedBox(key: key),
        ),
        LayoutBuilder(
          key: const ValueKey<int>(2),
          builder: (BuildContext context, BoxConstraints constraints) {
            return const Placeholder();
          },
        ),
      ],
    ));

    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(
          key: const ValueKey<int>(1),
          child: const Placeholder(),
        ),
        LayoutBuilder(
          key: const ValueKey<int>(2),
          builder: (BuildContext context, BoxConstraints constraints) {
            return SizedBox(key: key);
          },
        ),
      ],
    ));
  });

  testWidgets('GlobalKey correct case 2 - can move global key from layoutbuilder to container widget', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'correct');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(
          key: const ValueKey<int>(1),
          child: const Placeholder(),
        ),
        LayoutBuilder(
          key: const ValueKey<int>(2),
          builder: (BuildContext context, BoxConstraints constraints) {
            return SizedBox(key: key);
          },
        ),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(
          key: const ValueKey<int>(1),
          child: SizedBox(key: key),
        ),
        LayoutBuilder(
          key: const ValueKey<int>(2),
          builder: (BuildContext context, BoxConstraints constraints) {
            return const Placeholder();
          },
        ),
      ],
    ));
  });

  testWidgets('GlobalKey correct case 3 - can deal with early rebuild in layoutbuilder - move backward', (WidgetTester tester) async {
    const Key key1 = GlobalObjectKey('Text1');
    const Key key2 = GlobalObjectKey('Text2');
    Key rebuiltKeyOfSecondChildBeforeLayout;
    Key rebuiltKeyOfFirstChildAfterLayout;
    Key rebuiltKeyOfSecondChildAfterLayout;
    await tester.pumpWidget(
      LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Column(
            children: <Widget>[
              const _Stateful(
                child: Text(
                  'Text1',
                  textDirection: TextDirection.ltr,
                  key: key1,
                ),
              ),
              _Stateful(
                child: const Text(
                  'Text2',
                  textDirection: TextDirection.ltr,
                  key: key2,
                ),
                onElementRebuild: (StatefulElement element) {
                  // We don't want noise to override the result;
                  expect(rebuiltKeyOfSecondChildBeforeLayout, isNull);
                  final _Stateful statefulWidget = element.widget as _Stateful;
                  rebuiltKeyOfSecondChildBeforeLayout =
                    statefulWidget.child.key;
                },
              ),
            ],
          );
        },
      )
    );
    // Result will be written during first build and need to clear it to remove
    // noise.
    rebuiltKeyOfSecondChildBeforeLayout = null;

    final _StatefulState state = tester.firstState(find.byType(_Stateful).at(1));
    state.rebuild();
    // Reorders the items
    await tester.pumpWidget(
      LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Column(
            children: <Widget>[
              _Stateful(
                child: const Text(
                  'Text2',
                  textDirection: TextDirection.ltr,
                  key: key2,
                ),
                onElementRebuild: (StatefulElement element) {
                  // Verifies the early rebuild happens before layout.
                  expect(rebuiltKeyOfSecondChildBeforeLayout, key2);
                  // We don't want noise to override the result;
                  expect(rebuiltKeyOfFirstChildAfterLayout, isNull);
                  final _Stateful statefulWidget = element.widget as _Stateful;
                  rebuiltKeyOfFirstChildAfterLayout = statefulWidget.child.key;
                },
              ),
              _Stateful(
                child: const Text(
                  'Text1',
                  textDirection: TextDirection.ltr,
                  key: key1,
                ),
                onElementRebuild: (StatefulElement element) {
                  // Verifies the early rebuild happens before layout.
                  expect(rebuiltKeyOfSecondChildBeforeLayout, key2);
                  // We don't want noise to override the result;
                  expect(rebuiltKeyOfSecondChildAfterLayout, isNull);
                  final _Stateful statefulWidget = element.widget as _Stateful;
                  rebuiltKeyOfSecondChildAfterLayout = statefulWidget.child.key;
                },
              ),
            ],
          );
        },
      )
    );
    expect(rebuiltKeyOfSecondChildBeforeLayout, key2);
    expect(rebuiltKeyOfFirstChildAfterLayout, key2);
    expect(rebuiltKeyOfSecondChildAfterLayout, key1);
  });

  testWidgets('GlobalKey correct case 4 - can deal with early rebuild in layoutbuilder - move forward', (WidgetTester tester) async {
    const Key key1 = GlobalObjectKey('Text1');
    const Key key2 = GlobalObjectKey('Text2');
    const Key key3 = GlobalObjectKey('Text3');
    Key rebuiltKeyOfSecondChildBeforeLayout;
    Key rebuiltKeyOfSecondChildAfterLayout;
    Key rebuiltKeyOfThirdChildAfterLayout;
    await tester.pumpWidget(
      LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Column(
            children: <Widget>[
              const _Stateful(
                child: Text(
                  'Text1',
                  textDirection: TextDirection.ltr,
                  key: key1,
                ),
              ),
              _Stateful(
                child: const Text(
                  'Text2',
                  textDirection: TextDirection.ltr,
                  key: key2,
                ),
                onElementRebuild: (StatefulElement element) {
                  // We don't want noise to override the result;
                  expect(rebuiltKeyOfSecondChildBeforeLayout, isNull);
                  final _Stateful statefulWidget = element.widget as _Stateful;
                  rebuiltKeyOfSecondChildBeforeLayout = statefulWidget.child.key;
                },
              ),
              const _Stateful(
                child: Text(
                  'Text3',
                  textDirection: TextDirection.ltr,
                  key: key3,
                ),
              ),
            ],
          );
        },
      )
    );
    // Result will be written during first build and need to clear it to remove
    // noise.
    rebuiltKeyOfSecondChildBeforeLayout = null;

    final _StatefulState state = tester.firstState(find.byType(_Stateful).at(1));
    state.rebuild();
    // Reorders the items
    await tester.pumpWidget(
      LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Column(
            children: <Widget>[
              const _Stateful(
                child: Text(
                  'Text1',
                  textDirection: TextDirection.ltr,
                  key: key1,
                ),
              ),
              _Stateful(
                child: const Text(
                  'Text3',
                  textDirection: TextDirection.ltr,
                  key: key3,
                ),
                onElementRebuild: (StatefulElement element) {
                  // Verifies the early rebuild happens before layout.
                  expect(rebuiltKeyOfSecondChildBeforeLayout, key2);
                  // We don't want noise to override the result;
                  expect(rebuiltKeyOfSecondChildAfterLayout, isNull);
                  final _Stateful statefulWidget = element.widget as _Stateful;
                  rebuiltKeyOfSecondChildAfterLayout = statefulWidget.child.key;
                },
              ),
              _Stateful(
                child: const Text(
                  'Text2',
                  textDirection: TextDirection.ltr,
                  key: key2,
                ),
                onElementRebuild: (StatefulElement element) {
                  // Verifies the early rebuild happens before layout.
                  expect(rebuiltKeyOfSecondChildBeforeLayout, key2);
                  // We don't want noise to override the result;
                  expect(rebuiltKeyOfThirdChildAfterLayout, isNull);
                  final _Stateful statefulWidget = element.widget as _Stateful;
                  rebuiltKeyOfThirdChildAfterLayout = statefulWidget.child.key;
                },
              ),
            ],
          );
        },
      )
    );
    expect(rebuiltKeyOfSecondChildBeforeLayout, key2);
    expect(rebuiltKeyOfSecondChildAfterLayout, key3);
    expect(rebuiltKeyOfThirdChildAfterLayout, key2);
  });

  testWidgets('GlobalKey correct case 5 - can deal with early rebuild in layoutbuilder - only one global key', (WidgetTester tester) async {
    const Key key1 = GlobalObjectKey('Text1');
    Key rebuiltKeyOfSecondChildBeforeLayout;
    Key rebuiltKeyOfThirdChildAfterLayout;
    await tester.pumpWidget(
      LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Column(
            children: <Widget>[
              const _Stateful(
                child: Text(
                  'Text1',
                  textDirection: TextDirection.ltr,
                ),
              ),
              _Stateful(
                child: const Text(
                  'Text2',
                  textDirection: TextDirection.ltr,
                  key: key1,
                ),
                onElementRebuild: (StatefulElement element) {
                  // We don't want noise to override the result;
                  expect(rebuiltKeyOfSecondChildBeforeLayout, isNull);
                  final _Stateful statefulWidget = element.widget as _Stateful;
                  rebuiltKeyOfSecondChildBeforeLayout = statefulWidget.child.key;
                },
              ),
              const _Stateful(
                child: Text(
                  'Text3',
                  textDirection: TextDirection.ltr,
                ),
              ),
            ],
          );
        },
      )
    );
    // Result will be written during first build and need to clear it to remove
    // noise.
    rebuiltKeyOfSecondChildBeforeLayout = null;

    final _StatefulState state = tester.firstState(find.byType(_Stateful).at(1));
    state.rebuild();
    // Reorders the items
    await tester.pumpWidget(
      LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Column(
            children: <Widget>[
              const _Stateful(
                child: Text(
                  'Text1',
                  textDirection: TextDirection.ltr,
                ),
              ),
              _Stateful(
                child: const Text(
                  'Text3',
                  textDirection: TextDirection.ltr,
                ),
                onElementRebuild: (StatefulElement element) {
                  // Verifies the early rebuild happens before layout.
                  expect(rebuiltKeyOfSecondChildBeforeLayout, key1);
                },
              ),
              _Stateful(
                child: const Text(
                  'Text2',
                  textDirection: TextDirection.ltr,
                  key: key1,
                ),
                onElementRebuild: (StatefulElement element) {
                  // Verifies the early rebuild happens before layout.
                  expect(rebuiltKeyOfSecondChildBeforeLayout, key1);
                  // We don't want noise to override the result;
                  expect(rebuiltKeyOfThirdChildAfterLayout, isNull);
                  final _Stateful statefulWidget = element.widget as _Stateful;
                  rebuiltKeyOfThirdChildAfterLayout = statefulWidget.child.key;
                },
              ),
            ],
          );
        },
      )
    );
    expect(rebuiltKeyOfSecondChildBeforeLayout, key1);
    expect(rebuiltKeyOfThirdChildAfterLayout, key1);
  });

  testWidgets('GlobalKey duplication 1 - double appearance', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(
          key: const ValueKey<int>(1),
          child: SizedBox(key: key),
        ),
        Container(
          key: const ValueKey<int>(2),
          child: Placeholder(key: key),
        ),
      ],
    ));
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    expect(
      exception.toString(),
      equalsIgnoringHashCodes(
        'Multiple widgets used the same GlobalKey.\n'
        'The key [GlobalKey#00000 problematic] was used by multiple widgets. The parents of those widgets were:\n'
        '- Container-[<1>]\n'
        '- Container-[<2>]\n'
        'A GlobalKey can only be specified on one widget at a time in the widget tree.'
      ),
    );
  });

  testWidgets('GlobalKey duplication 2 - splitting and changing type', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');

    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(
          key: const ValueKey<int>(1),
        ),
        Container(
          key: const ValueKey<int>(2),
        ),
        Container(
          key: key
        ),
      ],
    ));

    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(
          key: const ValueKey<int>(1),
          child: SizedBox(key: key),
        ),
        Container(
          key: const ValueKey<int>(2),
          child: Placeholder(key: key),
        ),
      ],
    ));

    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    expect(
      exception.toString(),
      equalsIgnoringHashCodes(
        'Multiple widgets used the same GlobalKey.\n'
        'The key [GlobalKey#00000 problematic] was used by multiple widgets. The parents of those widgets were:\n'
        '- Container-[<1>]\n'
        '- Container-[<2>]\n'
        'A GlobalKey can only be specified on one widget at a time in the widget tree.'
      ),
    );
  });

  testWidgets('GlobalKey duplication 3 - splitting and changing type', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        SizedBox(key: key),
        Placeholder(key: key),
      ],
    ));
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    expect(
      exception.toString(),
      equalsIgnoringHashCodes(
        'Multiple widgets used the same GlobalKey.\n'
        'The key [GlobalKey#00000 problematic] was used by 2 widgets:\n'
        '  SizedBox-[GlobalKey#00000 problematic]\n'
        '  Placeholder-[GlobalKey#00000 problematic]\n'
        'A GlobalKey can only be specified on one widget at a time in the widget tree.'
      ),
    );
  });

  testWidgets('GlobalKey duplication 4 - splitting and half changing type', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key),
        Placeholder(key: key),
      ],
    ));
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    expect(
      exception.toString(),
      equalsIgnoringHashCodes(
        'Multiple widgets used the same GlobalKey.\n'
        'The key [GlobalKey#00000 problematic] was used by 2 widgets:\n'
        '  Container-[GlobalKey#00000 problematic]\n'
        '  Placeholder-[GlobalKey#00000 problematic]\n'
        'A GlobalKey can only be specified on one widget at a time in the widget tree.'
      ),
    );
  });

  testWidgets('GlobalKey duplication 5 - splitting and half changing type', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Placeholder(key: key),
        Container(key: key),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 6 - splitting and not changing type', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key),
        Container(key: key),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 7 - appearing later', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(1), child: Container(key: key)),
        Container(key: const ValueKey<int>(2)),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(1), child: Container(key: key)),
        Container(key: const ValueKey<int>(2), child: Container(key: key)),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 8 - appearing earlier', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(1)),
        Container(key: const ValueKey<int>(2), child: Container(key: key)),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(1), child: Container(key: key)),
        Container(key: const ValueKey<int>(2), child: Container(key: key)),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 9 - moving and appearing later', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(0), child: Container(key: key)),
        Container(key: const ValueKey<int>(1)),
        Container(key: const ValueKey<int>(2)),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(0)),
        Container(key: const ValueKey<int>(1), child: Container(key: key)),
        Container(key: const ValueKey<int>(2), child: Container(key: key)),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 10 - moving and appearing earlier', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(1)),
        Container(key: const ValueKey<int>(2)),
        Container(key: const ValueKey<int>(3), child: Container(key: key)),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(1), child: Container(key: key)),
        Container(key: const ValueKey<int>(2), child: Container(key: key)),
        Container(key: const ValueKey<int>(3)),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 11 - double sibling appearance', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key),
        Container(key: key),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 12 - all kinds of badness at once', (WidgetTester tester) async {
    final Key key1 = GlobalKey(debugLabel: 'problematic');
    final Key key2 = GlobalKey(debugLabel: 'problematic'); // intentionally the same label
    final Key key3 = GlobalKey(debugLabel: 'also problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key1),
        Container(key: key1),
        Container(key: key2),
        Container(key: key1),
        Container(key: key1),
        Container(key: key2),
        Container(key: key1),
        Container(key: key1),
        Row(
          children: <Widget>[
            Container(key: key1),
            Container(key: key1),
            Container(key: key2),
            Container(key: key2),
            Container(key: key2),
            Container(key: key3),
            Container(key: key2),
          ],
        ),
        Row(
          children: <Widget>[
            Container(key: key1),
            Container(key: key1),
            Container(key: key3),
          ],
        ),
        Container(key: key3),
      ],
    ));
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    expect(
      exception.toString(),
      equalsIgnoringHashCodes(
        'Duplicate keys found.\n'
        'If multiple keyed nodes exist as children of another node, they must have unique keys.\n'
        'Stack(alignment: AlignmentDirectional.topStart, textDirection: ltr, fit: loose, overflow: clip) has multiple children with key [GlobalKey#00000 problematic].'
      ),
    );
  });

  testWidgets('GlobalKey duplication 13 - all kinds of badness at once', (WidgetTester tester) async {
    final Key key1 = GlobalKey(debugLabel: 'problematic');
    final Key key2 = GlobalKey(debugLabel: 'problematic'); // intentionally the same label
    final Key key3 = GlobalKey(debugLabel: 'also problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key1),
        Container(key: key2),
        Container(key: key3),
      ]),
    );
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key1),
        Container(key: key1),
        Container(key: key2),
        Container(key: key1),
        Container(key: key1),
        Container(key: key2),
        Container(key: key1),
        Container(key: key1),
        Row(
          children: <Widget>[
            Container(key: key1),
            Container(key: key1),
            Container(key: key2),
            Container(key: key2),
            Container(key: key2),
            Container(key: key3),
            Container(key: key2),
          ],
        ),
        Row(
          children: <Widget>[
            Container(key: key1),
            Container(key: key1),
            Container(key: key3),
          ],
        ),
        Container(key: key3),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 14 - moving during build - before', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key),
        Container(key: const ValueKey<int>(0)),
        Container(key: const ValueKey<int>(1)),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(0)),
        Container(key: const ValueKey<int>(1), child: Container(key: key)),
      ],
    ));
  });

  testWidgets('GlobalKey duplication 15 - duplicating during build - before', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key),
        Container(key: const ValueKey<int>(0)),
        Container(key: const ValueKey<int>(1)),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: key),
        Container(key: const ValueKey<int>(0)),
        Container(key: const ValueKey<int>(1), child: Container(key: key)),
      ],
    ));
    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('GlobalKey duplication 16 - moving during build - after', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(0)),
        Container(key: const ValueKey<int>(1)),
        Container(key: key),
      ],
    ));
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(0)),
        Container(key: const ValueKey<int>(1), child: Container(key: key)),
      ],
    ));
  });

  testWidgets('GlobalKey duplication 17 - duplicating during build - after', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(0)),
        Container(key: const ValueKey<int>(1)),
        Container(key: key),
      ],
    ));
    int count = 0;
    final FlutterExceptionHandler oldHandler = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      expect(details.exception, isFlutterError);
      count += 1;
    };
    await tester.pumpWidget(Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        Container(key: const ValueKey<int>(0)),
        Container(key: const ValueKey<int>(1), child: Container(key: key)),
        Container(key: key),
      ],
    ));
    FlutterError.onError = oldHandler;
    expect(count, 1);
  });

  testWidgets('GlobalKey duplication 18 - subtree build duplicate key with same type', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    final Stack stack = Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        const SwapKeyWidget(childKey: ValueKey<int>(0)),
        Container(key: const ValueKey<int>(1)),
        Container(key: key),
      ],
    );
    await tester.pumpWidget(stack);
    final SwapKeyWidgetState state = tester.state(find.byType(SwapKeyWidget));
    state.swapKey(key);
    await tester.pump();
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    expect(
      exception.toString(),
      equalsIgnoringHashCodes(
        'Duplicate GlobalKey detected in widget tree.\n'
        'The following GlobalKey was specified multiple times in the widget tree. This will lead '
        'to parts of the widget tree being truncated unexpectedly, because the second time a key is seen, the '
        'previous instance is moved to the new location. The key was:\n'
        '- [GlobalKey#00000 problematic]\n'
        'This was determined by noticing that after the widget with the above global key was '
        'moved out of its previous parent, that previous parent never updated during this frame, meaning that '
        'it either did not update at all or updated before the widget was moved, in either case implying that '
        'it still thinks that it should have a child with that global key.\n'
        'The specific parent that did not update after having one or more children forcibly '
        'removed due to GlobalKey reparenting is:\n'
        '- Stack(alignment: AlignmentDirectional.topStart, textDirection: ltr, fit: loose, '
        'overflow: clip, renderObject: RenderStack#00000)\n'
        'A GlobalKey can only be specified on one widget at a time in the widget tree.'
      ),
    );
  });

  testWidgets('GlobalKey duplication 19 - subtree build duplicate key with different types', (WidgetTester tester) async {
    final Key key = GlobalKey(debugLabel: 'problematic');
    final Stack stack = Stack(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        const SwapKeyWidget(childKey: ValueKey<int>(0)),
        Container(key: const ValueKey<int>(1)),
        Container(child: SizedBox(key: key)),
      ],
    );
    await tester.pumpWidget(stack);
    final SwapKeyWidgetState state = tester.state(find.byType(SwapKeyWidget));
    state.swapKey(key);
    await tester.pump();
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    expect(
      exception.toString(),
      equalsIgnoringHashCodes(
        'Multiple widgets used the same GlobalKey.\n'
        'The key [GlobalKey#95367 problematic] was used by 2 widgets:\n'
        '  SizedBox-[GlobalKey#00000 problematic]\n'
        '  Container-[GlobalKey#00000 problematic]\n'
        'A GlobalKey can only be specified on one widget at a time in the widget tree.'
      ),
    );
  });

  testWidgets('GlobalKey duplication 20 - real duplication with early rebuild in layoutbuilder will throw', (WidgetTester tester) async {
    const Key key1 = GlobalObjectKey('Text1');
    const Key key2 = GlobalObjectKey('Text2');
    Key rebuiltKeyOfSecondChildBeforeLayout;
    Key rebuiltKeyOfFirstChildAfterLayout;
    Key rebuiltKeyOfSecondChildAfterLayout;
    await tester.pumpWidget(
      LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Column(
            children: <Widget>[
              const _Stateful(
                child: Text(
                  'Text1',
                  textDirection: TextDirection.ltr,
                  key: key1,
                ),
              ),
              _Stateful(
                child: const Text(
                  'Text2',
                  textDirection: TextDirection.ltr,
                  key: key2,
                ),
                onElementRebuild: (StatefulElement element) {
                  // We don't want noise to override the result;
                  expect(rebuiltKeyOfSecondChildBeforeLayout, isNull);
                  final _Stateful statefulWidget = element.widget as _Stateful;
                  rebuiltKeyOfSecondChildBeforeLayout = statefulWidget.child.key;
                },
              ),
            ],
          );
        },
      )
    );
    // Result will be written during first build and need to clear it to remove
    // noise.
    rebuiltKeyOfSecondChildBeforeLayout = null;

    final _StatefulState state = tester.firstState(find.byType(_Stateful).at(1));
    state.rebuild();

    await tester.pumpWidget(
      LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Column(
            children: <Widget>[
              _Stateful(
                child: const Text(
                  'Text2',
                  textDirection: TextDirection.ltr,
                  key: key2,
                ),
                onElementRebuild: (StatefulElement element) {
                  // Verifies the early rebuild happens before layout.
                  expect(rebuiltKeyOfSecondChildBeforeLayout, key2);
                  // We don't want noise to override the result;
                  expect(rebuiltKeyOfFirstChildAfterLayout, isNull);
                  final _Stateful statefulWidget = element.widget as _Stateful;
                  rebuiltKeyOfFirstChildAfterLayout = statefulWidget.child.key;
                },
              ),
              _Stateful(
                child: const Text(
                  'Text1',
                  textDirection: TextDirection.ltr,
                  key: key2,
                ),
                onElementRebuild: (StatefulElement element) {
                  // Verifies the early rebuild happens before layout.
                  expect(rebuiltKeyOfSecondChildBeforeLayout, key2);
                  // We don't want noise to override the result;
                  expect(rebuiltKeyOfSecondChildAfterLayout, isNull);
                  final _Stateful statefulWidget = element.widget as _Stateful;
                  rebuiltKeyOfSecondChildAfterLayout = statefulWidget.child.key;
                },
              ),
            ],
          );
        },
      )
    );
    expect(rebuiltKeyOfSecondChildBeforeLayout, key2);
    expect(rebuiltKeyOfFirstChildAfterLayout, key2);
    expect(rebuiltKeyOfSecondChildAfterLayout, key2);
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    expect(
      exception.toString(),
      equalsIgnoringHashCodes(
        'Multiple widgets used the same GlobalKey.\n'
        'The key [GlobalObjectKey String#00000] was used by multiple widgets. The '
        'parents of those widgets were:\n'
        '- _Stateful(state: _StatefulState#00000)\n'
        '- _Stateful(state: _StatefulState#00000)\n'
        'A GlobalKey can only be specified on one widget at a time in the widget tree.'
      ),
    );
  });

  testWidgets('GlobalKey - dettach and re-attach child to different parents', (WidgetTester tester) async {
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Container(
          height: 100,
          child: CustomScrollView(
            controller: ScrollController(),
            slivers: <Widget>[
              SliverList(
                delegate: SliverChildListDelegate(<Widget>[
                  Text('child', key: GlobalKey()),
                ]),
              ),
            ],
          ),
        ),
      ),
    ));
    final SliverMultiBoxAdaptorElement element = tester.element(find.byType(SliverList));
    Element childElement;
    // Removing and recreating child with same Global Key should not trigger
    // duplicate key error.
    element.visitChildren((Element e) {
      childElement = e;
    });
    element.removeChild(childElement.renderObject as RenderBox);
    element.createChild(0, after: null);
    element.visitChildren((Element e) {
      childElement = e;
    });
    element.removeChild(childElement.renderObject as RenderBox);
    element.createChild(0, after: null);
  });

  testWidgets('Defunct setState throws exception', (WidgetTester tester) async {
    StateSetter setState;

    await tester.pumpWidget(StatefulBuilder(
      builder: (BuildContext context, StateSetter setter) {
        setState = setter;
        return Container();
      },
    ));

    // Control check that setState doesn't throw an exception.
    setState(() { });

    await tester.pumpWidget(Container());

    expect(() { setState(() { }); }, throwsFlutterError);
  });

  testWidgets('State toString', (WidgetTester tester) async {
    final TestState state = TestState();
    expect(state.toString(), contains('no widget'));
  });

  testWidgets('debugPrintGlobalKeyedWidgetLifecycle control test', (WidgetTester tester) async {
    expect(debugPrintGlobalKeyedWidgetLifecycle, isFalse);

    final DebugPrintCallback oldCallback = debugPrint;
    debugPrintGlobalKeyedWidgetLifecycle = true;

    final List<String> log = <String>[];
    debugPrint = (String message, { int wrapWidth }) {
      log.add(message);
    };

    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(Container(key: key));
    expect(log, isEmpty);
    await tester.pumpWidget(const Placeholder());
    debugPrint = oldCallback;
    debugPrintGlobalKeyedWidgetLifecycle = false;

    expect(log.length, equals(2));
    expect(log[0], matches('Deactivated'));
    expect(log[1], matches('Discarding .+ from inactive elements list.'));
  });

  testWidgets('MultiChildRenderObjectElement.children', (WidgetTester tester) async {
    GlobalKey key0, key1, key2;
    await tester.pumpWidget(Column(
      key: key0 = GlobalKey(),
      children: <Widget>[
        Container(),
        Container(key: key1 = GlobalKey()),
        Container(child: Container()),
        Container(key: key2 = GlobalKey()),
        Container(),
      ],
    ));
    final MultiChildRenderObjectElement element = key0.currentContext as MultiChildRenderObjectElement;
    expect(
      element.children.map((Element element) => element.widget.key),
      <Key>[null, key1, null, key2, null],
    );
  });

  testWidgets('Element diagnostics', (WidgetTester tester) async {
    GlobalKey key0;
    await tester.pumpWidget(Column(
      key: key0 = GlobalKey(),
      children: <Widget>[
        Container(),
        Container(key: GlobalKey()),
        Container(child: Container()),
        Container(key: GlobalKey()),
        Container(),
      ],
    ));
    final MultiChildRenderObjectElement element = key0.currentContext as MultiChildRenderObjectElement;

    expect(element, hasAGoodToStringDeep);
    expect(
      element.toStringDeep(),
      equalsIgnoringHashCodes(
        'Column-[GlobalKey#00000](direction: vertical, mainAxisAlignment: start, crossAxisAlignment: center, renderObject: RenderFlex#00000)\n'
        '├Container\n'
        '│└LimitedBox(maxWidth: 0.0, maxHeight: 0.0, renderObject: RenderLimitedBox#00000 relayoutBoundary=up1)\n'
        '│ └ConstrainedBox(BoxConstraints(biggest), renderObject: RenderConstrainedBox#00000 relayoutBoundary=up2)\n'
        '├Container-[GlobalKey#00000]\n'
        '│└LimitedBox(maxWidth: 0.0, maxHeight: 0.0, renderObject: RenderLimitedBox#00000 relayoutBoundary=up1)\n'
        '│ └ConstrainedBox(BoxConstraints(biggest), renderObject: RenderConstrainedBox#00000 relayoutBoundary=up2)\n'
        '├Container\n'
        '│└Container\n'
        '│ └LimitedBox(maxWidth: 0.0, maxHeight: 0.0, renderObject: RenderLimitedBox#00000 relayoutBoundary=up1)\n'
        '│  └ConstrainedBox(BoxConstraints(biggest), renderObject: RenderConstrainedBox#00000 relayoutBoundary=up2)\n'
        '├Container-[GlobalKey#00000]\n'
        '│└LimitedBox(maxWidth: 0.0, maxHeight: 0.0, renderObject: RenderLimitedBox#00000 relayoutBoundary=up1)\n'
        '│ └ConstrainedBox(BoxConstraints(biggest), renderObject: RenderConstrainedBox#00000 relayoutBoundary=up2)\n'
        '└Container\n'
        ' └LimitedBox(maxWidth: 0.0, maxHeight: 0.0, renderObject: RenderLimitedBox#00000 relayoutBoundary=up1)\n'
        '  └ConstrainedBox(BoxConstraints(biggest), renderObject: RenderConstrainedBox#00000 relayoutBoundary=up2)\n',
      ),
    );
  });

  testWidgets('Element diagnostics with null child', (WidgetTester tester) async {
    await tester.pumpWidget(const NullChildTest());
    final NullChildElement test = tester.element<NullChildElement>(find.byType(NullChildTest));
    test.includeChild = true;
    expect(
      tester.binding.renderViewElement.toStringDeep(),
      equalsIgnoringHashCodes(
        '[root](renderObject: RenderView#4a0f0)\n'
        '└NullChildTest(dirty)\n'
        ' └<null child>\n',
      ),
    );
    test.includeChild = false;
  });

  testWidgets('scheduleBuild while debugBuildingDirtyElements is true', (WidgetTester tester) async {
    /// ignore here is required for testing purpose because changing the flag properly is hard
    // ignore: invalid_use_of_protected_member
    tester.binding.debugBuildingDirtyElements = true;
    FlutterError error;
    try {
      tester.binding.buildOwner.scheduleBuildFor(
        DirtyElementWithCustomBuildOwner(tester.binding.buildOwner, Container()));
    } on FlutterError catch (e) {
      error = e;
    } finally {
      expect(error, isNotNull);
      expect(error.diagnostics.length, 3);
      expect(error.diagnostics.last.level, DiagnosticLevel.hint);
      expect(
        error.diagnostics.last.toStringDeep(),
        equalsIgnoringHashCodes(
          'This might be because setState() was called from a layout or\n'
          'paint callback. If a change is needed to the widget tree, it\n'
          'should be applied as the tree is being built. Scheduling a change\n'
          'for the subsequent frame instead results in an interface that\n'
          'lags behind by one frame. If this was done to make your build\n'
          'dependent on a size measured at layout time, consider using a\n'
          'LayoutBuilder, CustomSingleChildLayout, or\n'
          'CustomMultiChildLayout. If, on the other hand, the one frame\n'
          'delay is the desired effect, for example because this is an\n'
          'animation, consider scheduling the frame in a post-frame callback\n'
          'using SchedulerBinding.addPostFrameCallback or using an\n'
          'AnimationController to trigger the animation.\n',
        ),
      );
      expect(
        error.toStringDeep(),
        'FlutterError\n'
        '   Build scheduled during frame.\n'
        '   While the widget tree was being built, laid out, and painted, a\n'
        '   new frame was scheduled to rebuild the widget tree.\n'
        '   This might be because setState() was called from a layout or\n'
        '   paint callback. If a change is needed to the widget tree, it\n'
        '   should be applied as the tree is being built. Scheduling a change\n'
        '   for the subsequent frame instead results in an interface that\n'
        '   lags behind by one frame. If this was done to make your build\n'
        '   dependent on a size measured at layout time, consider using a\n'
        '   LayoutBuilder, CustomSingleChildLayout, or\n'
        '   CustomMultiChildLayout. If, on the other hand, the one frame\n'
        '   delay is the desired effect, for example because this is an\n'
        '   animation, consider scheduling the frame in a post-frame callback\n'
        '   using SchedulerBinding.addPostFrameCallback or using an\n'
        '   AnimationController to trigger the animation.\n',
      );
    }
  });

  testWidgets('didUpdateDependencies is not called on a State that never rebuilds', (WidgetTester tester) async {
    final GlobalKey<DependentState> key = GlobalKey<DependentState>();

    /// Initial build - should call didChangeDependencies, not deactivate
    await tester.pumpWidget(Inherited(1, child: DependentStatefulWidget(key: key)));
    final DependentState state = key.currentState;
    expect(key.currentState, isNotNull);
    expect(state.didChangeDependenciesCount, 1);
    expect(state.deactivatedCount, 0);

    /// Rebuild with updated value - should call didChangeDependencies
    await tester.pumpWidget(Inherited(2, child: DependentStatefulWidget(key: key)));
    expect(key.currentState, isNotNull);
    expect(state.didChangeDependenciesCount, 2);
    expect(state.deactivatedCount, 0);

    // reparent it - should call deactivate and didChangeDependencies
    await tester.pumpWidget(Inherited(3, child: SizedBox(child: DependentStatefulWidget(key: key))));
    expect(key.currentState, isNotNull);
    expect(state.didChangeDependenciesCount, 3);
    expect(state.deactivatedCount, 1);

    // Remove it - should call deactivate, but not didChangeDependencies
    await tester.pumpWidget(const Inherited(4, child: SizedBox()));
    expect(key.currentState, isNull);
    expect(state.didChangeDependenciesCount, 3);
    expect(state.deactivatedCount, 2);
  });
}

class NullChildTest extends Widget {
  const NullChildTest({ Key key }) : super(key: key);
  @override
  Element createElement() => NullChildElement(this);
}

class NullChildElement extends Element {
  NullChildElement(Widget widget) : super(widget);

  bool includeChild = false;

  @override
  void visitChildren(ElementVisitor visitor) {
    if (includeChild)
      visitor(null);
  }

  @override
  void performRebuild() { }
}


class DirtyElementWithCustomBuildOwner extends Element {
  DirtyElementWithCustomBuildOwner(BuildOwner buildOwner, Widget widget)
    : _owner = buildOwner, super(widget);

  final BuildOwner _owner;

  @override
  void performRebuild() {}

  @override
  BuildOwner get owner => _owner;

  @override
  bool get dirty => true;
}

class Inherited extends InheritedWidget {
  const Inherited(this.value, {Widget child, Key key}) : super(key: key, child: child);

  final int value;

  @override
  bool updateShouldNotify(Inherited oldWidget) => oldWidget.value != value;
}

class DependentStatefulWidget extends StatefulWidget {
  const DependentStatefulWidget({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => DependentState();
}

class DependentState extends State<DependentStatefulWidget> {
  int didChangeDependenciesCount = 0;
  int deactivatedCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    didChangeDependenciesCount += 1;
  }

  @override
  Widget build(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<Inherited>();
    return const SizedBox();
  }

  @override
  void deactivate() {
    super.deactivate();
    deactivatedCount += 1;
  }
}

class SwapKeyWidget extends StatefulWidget {
  const SwapKeyWidget({this.childKey}): super();

  final Key childKey;
  @override
  SwapKeyWidgetState createState() => SwapKeyWidgetState();
}

class SwapKeyWidgetState extends State<SwapKeyWidget> {
  Key key;

  @override
  void initState() {
    super.initState();
    key = widget.childKey;
  }

  void swapKey(Key newKey) {
    setState(() {
      key = newKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(key: key);
  }
}

class _Stateful extends StatefulWidget {
  const _Stateful({Key key, this.child, this.onElementRebuild}) : super(key: key);
  final Text child;
  final ElementRebuildCallback onElementRebuild;
  @override
  State<StatefulWidget> createState() => _StatefulState();

  @override
  StatefulElement createElement() => StatefulElementSpy(this);
}

class _StatefulState extends State<_Stateful> {
  void rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class StatefulElementSpy extends StatefulElement {
  StatefulElementSpy(StatefulWidget widget) : super(widget);

  _Stateful get _statefulWidget => widget as _Stateful;

  @override
  void rebuild() {
    if (_statefulWidget.onElementRebuild != null) {
      _statefulWidget.onElementRebuild(this);
    }
    super.rebuild();
  }
}
