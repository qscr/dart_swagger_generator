import 'package:dart_swagger_generator/dart_swagger_generator.dart';

void main(List<String> arguments) async {
  final generator = DartSwaggerGenerator();
  await generator.generateByUrl("http://gkh-test.bars-open.ru/test-rt/swagger/docs/v1");
}
