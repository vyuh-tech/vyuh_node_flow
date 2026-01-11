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
library;

// Core
export 'core/constants.dart';
export 'core/models.dart';

// Evaluation
export 'evaluation/evaluator.dart';
export 'evaluation/evaluation_service.dart';

// Presentation
export 'presentation/state.dart';
export 'presentation/theme.dart';

// Utils
export 'utils/connection_utils.dart';
export 'utils/formatters.dart';

// Main widget
export 'node_math_example.dart';

// Widgets
export 'widgets/widgets.dart';
