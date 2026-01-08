import 'package:vyuh_workflow_engine/vyuh_workflow_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Input / Output Types
// ─────────────────────────────────────────────────────────────────────────────

class ValidationInput {  // [!code focus]
  final Map<String, dynamic> data;
  final List<String> requiredFields;

  ValidationInput({required this.data, required this.requiredFields});

  factory ValidationInput.fromJson(Map<String, dynamic> json) => // ...
}

class ValidationOutput {  // [!code focus]
  final bool isValid;
  final Map<String, String> errors;

  ValidationOutput({required this.isValid, required this.errors});

  Map<String, dynamic> toJson() => // ...
}

// ─────────────────────────────────────────────────────────────────────────────
// Task Executor
// ─────────────────────────────────────────────────────────────────────────────

class ValidateDataTaskExecutor  // [!code focus]
    extends TypedTaskExecutor<ValidationInput, ValidationOutput> {  // [!code focus]

  static const schemaName = 'task.data.validate';

  static final typeDescriptor = TypeDescriptor<TaskExecutor>(  // [!code focus]
    schemaType: schemaName,  // [!code focus]
    fromJson: (json) => ValidateDataTaskExecutor(),  // [!code focus]
    title: 'Validate Data',  // [!code focus]
  );  // [!code focus]

  @override
  String get schemaType => schemaName;

  @override
  String get name => 'Validate Data';

  @override
  ValidationInput fromInput(Map<String, dynamic> input) =>
      ValidationInput.fromJson(input);

  @override
  Map<String, dynamic> toOutput(ValidationOutput output) =>
      output.toJson();

  @override
  Future<ValidationOutput> executeTyped(  // [!code focus]
    ValidationInput input,  // [!code focus]
    ExecutionContext context,  // [!code focus]
  ) async {  // [!code focus]
    final errors = <String, String>{};

    // Your validation logic here...

    return ValidationOutput(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Registration
// ─────────────────────────────────────────────────────────────────────────────

final workflowDescriptor = WorkflowDescriptor(  // [!code focus]
  tasks: [  // [!code focus]
    ValidateDataTaskExecutor.typeDescriptor,  // [!code focus]
  ],  // [!code focus]
);  // [!code focus]
