/// Node Math Calculator - A visual math expression editor example.
///
/// Demonstrates building a visual math expression editor using vyuh_node_flow.
///
/// ## Features
/// - Number input nodes with editable values
/// - Operator nodes (+, -, ×, ÷)
/// - Function nodes (sin, cos, sqrt)
/// - Result node showing expression and computed value
/// - Live evaluation with cycle detection
///
/// ## Usage
/// ```dart
/// import 'package:demo/examples/node_math/node_math.dart';
///
/// // Use the main widget
/// NodeMathExample()
/// ```
library node_math;

// Core
export 'constants.dart';
export 'evaluation.dart';
export 'models.dart';
export 'state.dart';
export 'theme.dart';
export 'utils.dart';

// Main widget
export 'node_math_example.dart';

// Widgets
export 'widgets/widgets.dart';
