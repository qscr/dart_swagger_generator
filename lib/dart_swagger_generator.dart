import 'dart:io';

import 'package:dart_swagger_generator/generation_template.dart';
import 'package:dart_swagger_generator/settings.dart';
import 'package:swagger_parser/models/enums.dart';
import 'package:swagger_parser/models/swagger_document/base_parameter.dart';
import 'package:swagger_parser/models/swagger_document/swagger_method.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:basic_utils/basic_utils.dart';

enum ModelType { request, response }

extension MethodTypeExtensions on MethodType {
  String toTypeString() {
    switch (this) {
      case MethodType.delete:
        return 'delete';
      case MethodType.post:
        return 'post';
      case MethodType.put:
        return 'put';
      case MethodType.get:
        return 'get';
    }
  }
}

/// Получить название метода по эндпоинту
String getMethodNameFromEndpoint({required String endpoint}) {
  final withoutJunk = endpoint
      .replaceAll(RegExp(r'(/{(.*)})'), '')
      .replaceAll(prefixToClean, '')
      .replaceAllMapped(RegExp(r'([A-Z])'), (match) => " ${match.group(0)}");
  final lastPart =
      withoutJunk.contains('/') ? withoutJunk.replaceAll('/', ' ').trim() : withoutJunk;
  return StringUtils.toPascalCase(lastPart);
}

class DartSwaggerGenerator {
  /// Сгенерировать модели по ссылке на json-описание OpenAPI
  Future<void> generateByUrl(String url) async {
    final swaggerDoc = await SwaggerParser().getDoc(url);

    final rootDirectory = await Directory('models').create();

    for (var method in swaggerDoc.methods) {
      await _generateMethod(
        method: method,
        rootDirectory: rootDirectory,
      );
    }
  }

  List<BaseParameter> normalizeParameters(List<BaseParameter> parameters) {
    final isWrapper = parameters.any((element) => element.name.contains('['));
    if (isWrapper && parameters.length == 1) {
      if (parameters.first.childParameters?.length == 2) {
        final newParameters = parameters.first.childParameters?.first.childParameters;
        if (newParameters != null) {
          return newParameters;
        }
      }
    }

    return parameters;
  }

  /// Генерация метода
  Future<void> _generateMethod({
    required SwaggerMethod method,
    required Directory rootDirectory,
  }) async {
    final methodNameCamelCase = getMethodNameFromEndpoint(endpoint: method.name);
    final methodNameSnakeCase = StringUtils.camelCaseToLowerUnderscore(methodNameCamelCase);

    final requestParameters = normalizeParameters(method.requestParameters ?? []);
    final responseParameters = normalizeParameters(method.responseParameters ?? []);
    // Создаем папку для моделей
    final methodDirectory =
        await Directory('${rootDirectory.path}/$methodNameSnakeCase/${method.type.toTypeString()}')
            .create(recursive: true);
    if (method.requestParameters != null) {
      await _generateModel(
        methodNameCamelCase:
            '${StringUtils.capitalize(method.type.toTypeString())}$methodNameCamelCase',
        parameters: requestParameters,
        methodDirectory: methodDirectory,
        description: method.description,
        modelType: ModelType.request,
      );
    }
    if (method.responseParameters != null) {
      await _generateModel(
        methodNameCamelCase:
            '${StringUtils.capitalize(method.type.toTypeString())}$methodNameCamelCase',
        parameters: responseParameters,
        methodDirectory: methodDirectory,
        modelType: ModelType.response,
        description: method.description,
      );
    }
  }

  /// Генерация модели реквеста
  Future<String> _generateModel({
    required String methodNameCamelCase,
    required List<BaseParameter> parameters,
    required Directory methodDirectory,
    required ModelType modelType,
    String? description,
  }) async {
    final shortModelName = modelType == ModelType.request ? 'Req' : 'Resp';
    final longModelName = modelType == ModelType.request ? 'Request' : 'Response';
    final fileNameCamelCase = '$methodNameCamelCase$longModelName';
    if (parameters.isNotEmpty) {
      final fileNameSnakeCase = StringUtils.camelCaseToLowerUnderscore(fileNameCamelCase);
      final file = await File('${methodDirectory.path}/$fileNameSnakeCase.dart').create();
      String generatedParameters = '';
      for (var requestParameter in parameters) {
        String? generatedName;
        if (requestParameter.childParameters?.isNotEmpty ?? false) {
          final parameterPascalCase =
              requestParameter.name.replaceRange(0, 1, requestParameter.name[0].toUpperCase());
          generatedName = await _generateModel(
            methodNameCamelCase: '$methodNameCamelCase$parameterPascalCase',
            parameters: requestParameter.childParameters!,
            methodDirectory: methodDirectory,
            description: requestParameter.description,
            modelType: modelType,
          );
        }
        generatedParameters += generateParameter(
          description: requestParameter.description ?? '',
          modelType: generatedName != null
              ? requestParameter.type == ParameterType.array
                  ? 'List<$generatedName>'
                  : generatedName
              : requestParameter.childrenBaseType != null
                  ? 'List<${requestParameter.childrenBaseType!.toTypeString()}>'
                  : null,
          name: requestParameter.name,
          type: requestParameter.type,
        );
      }
      final result = freezedTemplate(
        filename: fileNameSnakeCase,
        filenameCamelCase: fileNameCamelCase,
        nestedModelName: '$methodNameCamelCase$shortModelName',
        parameters: generatedParameters,
      );
      await file.writeAsString(result);
    }
    return fileNameCamelCase;
  }
}
