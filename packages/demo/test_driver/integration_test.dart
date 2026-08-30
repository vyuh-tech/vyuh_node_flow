import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) {
    var reportName = 'node_flow_500';
    if (data != null) {
      for (final key in data.keys) {
        if (key.startsWith('node_flow_')) {
          reportName = key;
          break;
        }
      }
    }
    return writeResponseData(
      data,
      testOutputFilename: '${reportName}_benchmark',
    );
  },
);
