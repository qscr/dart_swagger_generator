import 'package:swagger_parser/models/enums.dart';

/// Генерирует Freezed-модель по шаблону
///
/// [filename] - имя файла (snake_case)
///
/// [filenameCamelCase] - имя файла (camel_case)
///
/// [nestedModelName] - название внутренней модели (camel_case)
///
/// [parameters] - блок с полями модели
///
/// [comment] - комментарий к модели
String freezedTemplate({
  required String filename,
  required String filenameCamelCase,
  required String nestedModelName,
  required String parameters,
  String? imports,
  String? comment,
}) {
  return '''import 'package:freezed_annotation/freezed_annotation.dart';${imports != null ? '\n$imports' : ''}

part '$filename.g.dart';
part '$filename.freezed.dart';
${comment != null ? '\n/// $comment' : ''}
@freezed
// ignore_for_file: invalid_annotation_target
class $filenameCamelCase with _\$$filenameCamelCase {
  const factory $filenameCamelCase({
$parameters
  }) = $nestedModelName;

  factory $filenameCamelCase.fromJson(Map<String, dynamic> json) => _\$${filenameCamelCase}FromJson(json);
}
''';
}

String generateParameter({
  required String description,
  String? modelType,
  ParameterType? type,
  required String name,
}) {
  return '''
    /// $description
    @JsonKey(name: "$name") ${modelType ?? type?.toTypeString()}? $name,

''';
}

String generateImport(String snakeCaseName) {
  return "import '$snakeCaseName.dart';\n";
}

extension ParameterTypeExtensions on ParameterType {
  String toTypeString() {
    switch (this) {
      case ParameterType.bool:
        return 'bool';
      case ParameterType.integer:
        return 'int';
      case ParameterType.double:
        return 'double';
      case ParameterType.string:
        return 'String';
      case ParameterType.file:
        return 'File';
      case ParameterType.number:
        return 'int';
      case ParameterType.boolean:
        return 'bool';
      default:
        return 'undefined';
    }
  }
}
