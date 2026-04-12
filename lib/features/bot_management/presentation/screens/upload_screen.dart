import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/business.dart';

class UploadScreen extends ConsumerStatefulWidget {
  final Business business;
  final String uploadType; // 'prices' или 'knowledge'

  const UploadScreen({
    super.key,
    required this.business,
    required this.uploadType,
  });

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  PlatformFile? _pickedFile;
  final _nameController = TextEditingController();
  bool _isUploading = false;
  Map<String, dynamic>? _usageInfo;

  // --- ЛОГИКА ДИНАМИЧЕСКИХ СТАТУСОВ ---
  Timer? _statusTimer;
  int _secondsElapsed = 0;
  String _currentStatusText = 'Загрузка файла...';

  final List<(int, String)> _uploadStages = [
    (0, 'Загрузка файла...'),
    (5, 'Обработка данных...'),
    (15, 'AI анализирует содержимое...'),
    (40, 'Оптимизируем поиск...'),
    (70, 'Почти готово...'),
  ];

  void _startStatusTimer() {
    _secondsElapsed = 0;
    _currentStatusText = _uploadStages[0].$2;

    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsElapsed++;
        for (var stage in _uploadStages.reversed) {
          if (_secondsElapsed >= stage.$1) {
            if (_currentStatusText != stage.$2) {
              _currentStatusText = stage.$2;
            }
            break;
          }
        }
      });
    });
  }

  void _stopStatusTimer() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  String get _screenTitle {
    if (widget.uploadType == 'prices') return 'Прайс-лист';
    return 'База знаний';
  }

  @override
  void dispose() {
    _stopStatusTimer();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final allowedExtensions =
        widget.uploadType == 'prices' ? ['xlsx', 'csv'] : ['txt', 'pdf'];

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      withData: kIsWeb,
    );

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
        final fileName = _pickedFile!.name;
        _nameController.text = fileName.contains('.')
            ? fileName
                .split('.')
                .sublist(0, fileName.split('.').length - 1)
                .join('.')
            : fileName;
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_pickedFile == null || _nameController.text.isEmpty) return;

    final botUrl = widget.business.serviceUrl ?? '';
    final businessUuid = widget.business.userId;

    if (botUrl.isEmpty) {
      _showSnackBar('Ошибка: URL инстанса не найден', isError: true);
      return;
    }

    setState(() => _isUploading = true);
    _startStatusTimer();

    // Создаем клиент для установки увеличенного таймаута
    final client = http.Client();

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$botUrl/api/upload/$businessUuid'),
      );

      request.fields['type'] = widget.uploadType;
      request.fields['document_name'] = _nameController.text.trim();

      if (kIsWeb || _pickedFile!.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          _pickedFile!.bytes!,
          filename: _pickedFile!.name,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          _pickedFile!.path!,
        ));
      }

      // Отправляем запрос через клиента с таймаутом 5 минут
      final streamedResponse = await client.send(request).timeout(
            const Duration(minutes: 5),
          );

      final response = await http.Response.fromStream(streamedResponse);

      _stopStatusTimer();

      if (response.body.isEmpty) throw Exception('Пустой ответ от сервера');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _usageInfo = data['usage'];
          _pickedFile = null;
        });
        _showSnackBar('Данные успешно загружены!');
      } else if (response.statusCode == 402) {
        _showLimitDialog(data['usage']);
      } else {
        throw Exception(data['error'] ?? 'Ошибка сервера');
      }
    } on TimeoutException catch (_) {
      _stopStatusTimer();
      _showSnackBar('Превышено время ожидания. Файл обрабатывается на сервере.',
          isError: true);
    } catch (e) {
      _stopStatusTimer();
      _showSnackBar('Ошибка: $e', isError: true);
    } finally {
      client.close(); // Обязательно закрываем клиент
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _payForUpload(int charsNeeded) async {
    try {
      await Supabase.instance.client.auth.refreshSession();

      final response = await Supabase.instance.client.functions.invoke(
        'create-upload-payment',
        body: {
          'businessId': widget.business.userId,
          'charsNeeded': charsNeeded,
        },
      );

      if (response.status == 200) {
        final url = response.data['url'] as String?;
        if (url != null) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          _showSnackBar('После оплаты нажмите "НАЧАТЬ ЗАГРУЗКУ" повторно');
        }
      } else {
        throw Exception(response.data['error'] ?? 'Ошибка создания сессии');
      }
    } catch (e) {
      _showSnackBar('Ошибка платежа: $e', isError: true);
    }
  }

  void _showLimitDialog(Map<String, dynamic> usage) {
    final int needed = usage['chars_needed'] ?? 0;
    final int cost = usage['estimated_cost'] ?? 1;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Лимит превышен',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Вам не хватает $needed символов для загрузки этого файла.',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Text('Стоимость доплаты: \$$cost',
                style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const Text('(Пакет 10,000 символов)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ОТМЕНА',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _payForUpload(needed);
            },
            child: Text('ОПЛАТИТЬ \$$cost',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(_screenTitle,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_usageInfo != null) _buildUsageProgress(),
            const SizedBox(height: 24),
            const Text('Документы в базе',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            _buildDocumentsPlaceholder(),
            const SizedBox(height: 32),
            if (_pickedFile == null)
              _buildActionButton(
                label: 'ВЫБРАТЬ ФАЙЛ',
                icon: Icons.attach_file,
                onPressed: _pickFile,
              )
            else
              _buildUploadForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.folder_open_outlined,
              size: 48, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text('Список документов будет доступен позже',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildUsageProgress() {
    final double used = (_usageInfo!['used'] as num).toDouble();
    final double limit = (_usageInfo!['limit'] as num).toDouble();
    final double credit =
        (_usageInfo!['credit_balance'] as num? ?? 0).toDouble();
    final double totalLimit = limit + credit;
    final double progress =
        (totalLimit > 0) ? (used / totalLimit).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Использование лимитов',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              if (credit > 0)
                Text('+$credit доп. симв.',
                    style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.background,
            color: progress > 0.9 ? AppColors.error : AppColors.accent,
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            'Использовано: ${used.toInt()} из ${totalLimit.toInt()} симв.',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: AppColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _pickedFile!.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Название документа',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              hintText: 'Введите название...',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: _isUploading ? 80 : 48,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _uploadFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                disabledBackgroundColor:
                    AppColors.accent.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isUploading
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _currentStatusText,
                            key: ValueKey(_currentStatusText),
                            style: const TextStyle(
                              color: Color(0xFFC9B8D8),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Text('НАЧАТЬ ЗАГРУЗКУ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _pickedFile = null),
              child: const Text('ОТМЕНА',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      {required String label,
      required IconData icon,
      required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
