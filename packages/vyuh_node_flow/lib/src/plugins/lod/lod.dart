/// Level of Detail (LOD) system for progressive rendering.
///
/// The LOD system controls which visual elements are rendered based on
/// the current zoom level. This improves performance for large graphs
/// and reduces visual clutter when zoomed out.
///
/// Key classes:
/// - [DetailVisibility] - Configuration for which elements are visible
/// - [LodPlugin] - Plugin that provides reactive visibility state
library;

export 'detail_visibility.dart';
export 'lod_plugin.dart';
