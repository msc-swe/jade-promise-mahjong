import '../layout.dart';
import 'shapes.dart';
import 'turtle.dart';

final Map<String, Layout> _layouts = {};

const Map<String, Layout Function()> _builders = {
  'turtle': buildTurtle,
  'fortress': buildFortress,
  'keep': buildKeep,
  'tower': buildTower,
  'cross': buildCross,
  'pyramid': buildPyramid,
  'bridge': buildBridge,
  'stairs': buildStairs,
  'twin_peaks': buildTwinPeaks,
  'lantern': buildLantern,
  'arena': buildArena,
  'garden': buildGarden,
  'spire': buildSpire,
  'meadow': buildMeadow,
  'pagoda': buildPagoda,
  'tutorial': buildTutorial,
};

/// Layout ids are part of certificates; never change an existing layout's
/// geometry. Publish a new id instead.
Layout layoutById(String id) {
  return _layouts.putIfAbsent(id, () {
    final build = _builders[id];
    if (build == null) throw ArgumentError.value(id, 'id', 'unknown layout');
    return build();
  });
}

/// Every layout, including the tutorial board.
List<String> get layoutIds => _builders.keys.toList();

/// Playable layouts in rough order of difficulty (used by level mode): the
/// short boards first, then the full 144-tile layouts.
const List<String> levelLayoutIds = [
  'garden', 'spire', 'meadow', 'pagoda', // 72-100 tiles
  'fortress', 'pyramid', 'keep', 'arena', 'stairs', 'lantern', //
  'cross', 'bridge', 'tower', 'twin_peaks', 'turtle',
];
