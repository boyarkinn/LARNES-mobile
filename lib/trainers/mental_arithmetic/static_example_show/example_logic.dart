/// Web v2: `platform/src/trainers/mental-arithmetic/static-example-show/example-logic.ts`

const staticExampleOperations = ['add', 'subtract'];

typedef StaticExampleOperation = String;

bool isStaticExampleOperation(String? value) {
  return value != null && staticExampleOperations.contains(value);
}

int maxValueForRods(int totalRods) {
  if (totalRods < 1) {
    return 0;
  }

  var result = 1;
  for (var index = 0; index < totalRods; index++) {
    result *= 10;
  }
  return result - 1;
}

({int leftValue, int rightValue}) resolveStaticExampleAbacusValues({
  required StaticExampleOperation operation,
  required int operandA,
  required int operandB,
}) {
  final leftValue = operandA;
  final rightValue = operation == 'add' ? operandA + operandB : operandA - operandB;

  return (leftValue: leftValue, rightValue: rightValue);
}

String formatStaticExampleExpression({
  required StaticExampleOperation operation,
  required int operandA,
  required int operandB,
}) {
  final sign = operation == 'add' ? '+' : '−';

  return '$operandA $sign $operandB';
}
