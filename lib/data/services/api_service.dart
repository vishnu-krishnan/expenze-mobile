import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/config/api_config.dart';
import '../../core/constants/ai_prompts.dart';

enum AiProvider { groq, claude, openai }

class ApiService {
  late final Dio _dio;
  final Logger _logger = Logger();
  String? _token;

  Map<AiProvider, List<String>> _keyPools = {
    AiProvider.groq: [],
    AiProvider.claude: [],
    AiProvider.openai: [],
  };

  final Map<AiProvider, int> _poolIndices = {
    AiProvider.groq: 0,
    AiProvider.claude: 0,
    AiProvider.openai: 0,
  };

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          _logger.i('REQUEST[${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.i(
              'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          _logger.e(
              'ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
          return handler.next(e);
        },
      ),
    );

    reloadKeys();
  }

  Future<void> reloadKeys() async {
    // Clear and reload
    _keyPools = {
      AiProvider.groq: [],
      AiProvider.claude: [],
      AiProvider.openai: [],
    };

    // 1. Try to load from .ai_keys asset (if bundled)
    try {
      final content = await rootBundle.loadString('.ai_keys');
      final lines = content.split('\n');
      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty || line.startsWith('#')) continue;

        if (line.contains('=')) {
          final parts = line.split('=');
          if (parts.length < 2) continue;
          final keyName = parts[0].trim().toUpperCase();
          final value = parts[1].trim();

          if (keyName.contains('GROQ')) {
            _keyPools[AiProvider.groq]!.add(value);
          } else if (keyName.contains('CLAUDE')) {
            _keyPools[AiProvider.claude]!.add(value);
          } else if (keyName.contains('OPENAI')) {
            _keyPools[AiProvider.openai]!.add(value);
          }
        } else if (line.startsWith('sk-') || line.startsWith('gsk_')) {
          // Detect provider by prefix
          if (line.startsWith('gsk_')) {
            _keyPools[AiProvider.groq]!.add(line);
          } else if (line.contains('ant-api')) {
            _keyPools[AiProvider.claude]!.add(line);
          } else {
            _keyPools[AiProvider.openai]!.add(line);
          }
        }
      }
    } catch (e) {
      _logger.w('No .ai_keys asset found or error reading: $e');
    }

    // 2. Merge with dotenv keys (optional fallback/override)
    for (var key in dotenv.env.keys) {
      final value = dotenv.env[key];
      if (value == null || value.isEmpty) continue;

      final keyName = key.toUpperCase();
      if (keyName.contains('GROQ')) {
        if (!_keyPools[AiProvider.groq]!.contains(value)) {
          _keyPools[AiProvider.groq]!.add(value);
        }
      } else if (keyName.contains('CLAUDE')) {
        if (!_keyPools[AiProvider.claude]!.contains(value)) {
          _keyPools[AiProvider.claude]!.add(value);
        }
      } else if (keyName.contains('OPENAI')) {
        if (!_keyPools[AiProvider.openai]!.contains(value)) {
          _keyPools[AiProvider.openai]!.add(value);
        }
      }
    }

    // Remove duplicates and sort for deterministic rotation
    _keyPools.forEach((k, v) {
      final unique = v.toSet().toList();
      unique.sort();
      _keyPools[k] = unique;
    });

    _logger.i('AI Key Pool Refreshed: '
        'Groq(${_keyPools[AiProvider.groq]!.length}), '
        'Claude(${_keyPools[AiProvider.claude]!.length}), '
        'OpenAI(${_keyPools[AiProvider.openai]!.length})');
  }

  String _getNextKey(AiProvider provider) {
    final pool = _keyPools[provider];
    if (pool == null || pool.isEmpty) return '';

    int currentIndex = _poolIndices[provider]!;
    String key = pool[currentIndex];

    // Proactive Check: If the key looks like a placeholder (from .ai_keys example), skip it
    if (key.contains('abcdef123456') ||
        key.length < 20 ||
        key.contains('placeholder')) {
      _logger.w('[$provider] Skipping placeholder key at index $currentIndex');
      _poolIndices[provider] = (currentIndex + 1) % pool.length;
      return _getNextKey(provider); // Recursive call to get the next one
    }

    // Rotate for next time
    _poolIndices[provider] = (currentIndex + 1) % pool.length;

    return key;
  }

  void setToken(String? token) {
    _token = token;
  }

  // Auth Operations
  Future<Response> login(String username, String password) async {
    try {
      return await _dio.post(
        ApiConfig.loginEndpoint,
        data: {
          'username': username,
          'password': password,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> register(Map<String, dynamic> data) async {
    try {
      return await _dio.post(ApiConfig.registerEndpoint, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> verifyOtp(String email, String otp) async {
    try {
      return await _dio.post(
        ApiConfig.verifyOtpEndpoint,
        data: {
          'email': email,
          'otp': otp,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> resendOtp(String email) async {
    try {
      return await _dio.post(
        ApiConfig.resendOtpEndpoint,
        data: {'email': email},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getRegistrationStatus(String email) async {
    try {
      return await _dio.get('${ApiConfig.registrationStatusEndpoint}/$email');
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getOtpTimeout() async {
    try {
      return await _dio.get(ApiConfig.otpTimeoutEndpoint);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> resetPassword(String token, String newPassword) async {
    try {
      return await _dio.post(
        ApiConfig.resetPasswordEndpoint,
        data: {
          'token': token,
          'newPassword': newPassword,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // Profile endpoints
  Future<Response> getProfile() async {
    try {
      return await _dio.get(ApiConfig.profileEndpoint);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> updateProfile({String? phone, double? defaultBudget}) async {
    try {
      return await _dio.put(
        ApiConfig.profileEndpoint,
        data: {
          if (phone != null) 'phone': phone,
          if (defaultBudget != null) 'defaultBudget': defaultBudget,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> requestEmailChange(String newEmail) async {
    try {
      return await _dio.post(
        '${ApiConfig.profileEndpoint}/request-email-change',
        data: {'newEmail': newEmail},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> verifyEmailChange(String otp) async {
    try {
      return await _dio.post(
        '${ApiConfig.profileEndpoint}/verify-email-change',
        data: {'otp': otp},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Month Plan endpoints
  Future<Response> getMonth(String monthKey) async {
    try {
      return await _dio.get('${ApiConfig.monthEndpoint}/$monthKey');
    } catch (e) {
      rethrow;
    }
  }

  // Summary endpoints
  Future<Response> getSummary() async {
    try {
      return await _dio.get(ApiConfig.summaryEndpoint);
    } catch (e) {
      rethrow;
    }
  }

  // Category expenses
  Future<Response> getCategoryExpenses(String monthKey) async {
    try {
      return await _dio.get('${ApiConfig.categoryExpensesEndpoint}/$monthKey');
    } catch (e) {
      rethrow;
    }
  }

  // Regular payments
  Future<Response> getRegularPayments() async {
    try {
      return await _dio.get(ApiConfig.regularEndpoint);
    } catch (e) {
      rethrow;
    }
  }

  // SMS Import
  Future<Response> importSms(List<Map<String, dynamic>> messages) async {
    try {
      return await _dio.post(
        ApiConfig.smsImportEndpoint,
        data: {'messages': messages},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> aiParseSms(String text, List<String> categories,
      {String? userName, AiProvider? provider}) async {
    final envProvider = dotenv.env['AI_PROVIDER']?.toLowerCase();

    final preferredProvider = provider ??
        (envProvider == 'claude'
            ? AiProvider.claude
            : envProvider == 'groq'
                ? AiProvider.groq
                : AiProvider.openai); // Default to OpenAI

    // Determine retry limit based on key pool size
    int retryLimit = 3; // Baseline
    if (preferredProvider == AiProvider.openai) {
      // OpenAI has 50 keys, allow more rotations
      retryLimit = (_keyPools[AiProvider.openai]?.length ?? 10).clamp(5, 20);
    } else if (preferredProvider == AiProvider.groq) {
      retryLimit = (_keyPools[AiProvider.groq]?.length ?? 3).clamp(3, 5);
    }

    return _parseWithRetry(text, categories, preferredProvider,
        userName: userName, retryLimit: retryLimit);
  }

  Future<Response> _parseWithRetry(
      String text, List<String> categories, AiProvider provider,
      {String? userName, int retryLimit = 3}) async {
    try {
      final apiKey = _getNextKey(provider);
      if (apiKey.isEmpty) {
        _logger.w('[$provider] No keys available. Attempting fallback...');
        return _handleModelFallback(text, categories, provider, userName);
      }

      _logger.d('[$provider] Attempting parse (Retries left: $retryLimit)');

      switch (provider) {
        case AiProvider.groq:
          return await _parseWithGroq(text, categories, apiKey,
              userName: userName);
        case AiProvider.claude:
          return await _parseWithClaude(text, categories, apiKey,
              userName: userName);
        case AiProvider.openai:
          return await _parseWithOpenAI(text, categories, apiKey,
              userName: userName);
      }
    } catch (e) {
      int? statusCode;
      if (e is DioException) {
        statusCode = e.response?.statusCode;
      }

      _logger.w('[$provider] Command failed with status: $statusCode');

      // 1. If it's a "Recoverable" error (Rate Limit or Auth), try ROTATING keys for SAME provider
      if ((statusCode == 429 || statusCode == 401) && retryLimit > 0) {
        _logger.i('[$provider] Rotating key and retrying same provider...');
        return await _parseWithRetry(text, categories, provider,
            userName: userName, retryLimit: retryLimit - 1);
      }

      // 2. If same-provider retries exhausted or other error, try NEXT provider in chain
      _logger.e(
          '[$provider] Critical error or retries exhausted. Cascading to fallback...');
      return _handleModelFallback(text, categories, provider, userName);
    }
  }

  Future<Response> _handleModelFallback(String text, List<String> categories,
      AiProvider failedProvider, String? userName) async {
    // Define a strictly linear fallback chain to avoid circular loops
    // Order: Claude -> Groq -> OpenAI
    final List<AiProvider> chain = [
      AiProvider.claude,
      AiProvider.groq,
      AiProvider.openai
    ];

    final failedIndex = chain.indexOf(failedProvider);

    // Try providers AFTER the failed one in the chain
    for (int i = failedIndex + 1; i < chain.length; i++) {
      final nextProvider = chain[i];
      if (_keyPools[nextProvider]!.isNotEmpty) {
        _logger.i('Cascading: $failedProvider -> $nextProvider');
        return await _parseWithRetry(text, categories, nextProvider,
            userName: userName, retryLimit: 2); // Less retries for fallbacks
      }
    }

    // Special Case: If we started with something else, try Claude if we haven't yet
    // (This handles cases where the chain starts in the middle)
    for (int i = 0; i < failedIndex; i++) {
      final nextProvider = chain[i];
      if (_keyPools[nextProvider]!.isNotEmpty) {
        _logger.i('Cascading (Rewind): $failedProvider -> $nextProvider');
        return await _parseWithRetry(text, categories, nextProvider,
            userName: userName, retryLimit: 2);
      }
    }

    throw Exception(
        'All AI providers (Claude, Groq, OpenAI) have failed. Please check your API keys and internet connection.');
  }

  Future<Response> _parseWithGroq(
      String text, List<String> categories, String apiKey,
      {String? userName}) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.groq.com/openai/v1',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      ),
    );

    final prompt = AiPrompts.getSmsParsePrompt(categories, userName: userName);

    final payload = {
      'model': 'llama-3.1-8b-instant', // Higher rate limits on free tier
      'response_format': {'type': 'json_object'},
      'messages': [
        {'role': 'system', 'content': prompt},
        {'role': 'user', 'content': text},
      ],
      'temperature': 0.1,
    };

    try {
      final rawResponse = await dio.post('/chat/completions', data: payload);
      final choices = rawResponse.data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw Exception('Empty response from Groq API');
      }

      final content = choices[0]['message']['content'] as String? ?? '{}';
      final Map<String, dynamic> parsedData = json.decode(content);

      return Response(
        requestOptions: rawResponse.requestOptions,
        statusCode: 200,
        data: parsedData,
      );
    } catch (e) {
      _logger.e('Groq parse error: $e');
      rethrow;
    }
  }

  Future<Response> _parseWithClaude(
      String text, List<String> categories, String apiKey,
      {String? userName}) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.anthropic.com/v1',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
      ),
    );

    final prompt = AiPrompts.getSmsParsePrompt(categories, userName: userName);

    final payload = {
      'model': 'claude-3-5-sonnet-20240620',
      'max_tokens': 4096,
      'system': prompt,
      'messages': [
        {'role': 'user', 'content': text},
      ],
      'temperature': 0.1,
    };

    try {
      final rawResponse = await dio.post('/messages', data: payload);
      final content = rawResponse.data['content'] as List<dynamic>?;
      if (content == null || content.isEmpty) {
        throw Exception('Empty response from Claude API');
      }

      // Claude might return JSON inside text block
      String textContent = content[0]['text'] as String? ?? '{}';

      // Clean markdown if AI included it despite prompt
      if (textContent.contains('```json')) {
        textContent = textContent.split('```json')[1].split('```')[0].trim();
      } else if (textContent.contains('```')) {
        textContent = textContent.split('```')[1].split('```')[0].trim();
      }

      final Map<String, dynamic> parsedData = json.decode(textContent);

      return Response(
        requestOptions: rawResponse.requestOptions,
        statusCode: 200,
        data: parsedData,
      );
    } catch (e) {
      _logger.e('Claude parse error: $e');
      rethrow;
    }
  }

  Future<Response> _parseWithOpenAI(
      String text, List<String> categories, String apiKey,
      {String? userName}) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.openai.com/v1',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      ),
    );

    final prompt = AiPrompts.getSmsParsePrompt(categories, userName: userName);

    final payload = {
      'model': 'gpt-4o-mini',
      'response_format': {'type': 'json_object'},
      'messages': [
        {'role': 'system', 'content': prompt},
        {'role': 'user', 'content': text},
      ],
      'temperature': 0.1,
    };

    try {
      final rawResponse = await dio.post('/chat/completions', data: payload);
      final choices = rawResponse.data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw Exception('Empty response from OpenAI API');
      }

      final content = choices[0]['message']['content'] as String? ?? '{}';
      final Map<String, dynamic> parsedData = json.decode(content);

      return Response(
        requestOptions: rawResponse.requestOptions,
        statusCode: 200,
        data: parsedData,
      );
    } catch (e) {
      _logger.e('OpenAI parse error: $e');
      rethrow;
    }
  }
}
