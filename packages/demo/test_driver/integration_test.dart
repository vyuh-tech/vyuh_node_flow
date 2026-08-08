import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) =>
      writeResponseData(data, testOutputFilename: 'node_flow_500_benchmark'),
);
