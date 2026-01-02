import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/converter/text_converter.dart';

/// صفحه اصلی اپلیکیشن
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _encodeController = TextEditingController();
  final TextEditingController _decodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _decodePasswordController = TextEditingController();
  
  List<String> _encodeResults = [];
  String _decodeResult = '';
  int _selectedParts = 3; // پیش‌فرض ۳ پیامک
  int _estimatedParts = 1;
  bool _optimizeLinks = false; // بهینه‌سازی لینک‌ها
  OutputMode _outputMode = OutputMode.compact; // حالت خروجی

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _encodeController.dispose();
    _decodeController.dispose();
    _passwordController.dispose();
    _decodePasswordController.dispose();
    super.dispose();
  }

  void _encode() {
    final input = _encodeController.text;
    if (input.isEmpty) {
      _showSnackBar('لطفاً متنی وارد کنید');
      return;
    }
    if (_outputMode == OutputMode.encrypted && _passwordController.text.isEmpty) {
      _showSnackBar('لطفاً رمز عبور وارد کنید');
      return;
    }
    setState(() {
      _encodeResults = TextConverter.encode(
        input, 
        parts: _selectedParts, 
        optimize: _optimizeLinks,
        mode: _outputMode,
        password: _outputMode == OutputMode.encrypted ? _passwordController.text : null,
      );
    });
  }

  void _updateEstimate() {
    final input = _encodeController.text;
    if (input.isNotEmpty) {
      setState(() {
        _estimatedParts = TextConverter.estimateParts(
          input, 
          optimize: _optimizeLinks,
          mode: _outputMode,
        );
        if (_selectedParts < _estimatedParts) {
          _selectedParts = _estimatedParts;
        }
      });
    }
  }

  void _decode() {
    final input = _decodeController.text;
    if (input.isEmpty) {
      _showSnackBar('لطفاً متنی وارد کنید');
      return;
    }
    
    // چک کردن نیاز به رمز عبور
    final needsPassword = TextConverter.isEncryptedText(input);
    if (needsPassword && _decodePasswordController.text.isEmpty) {
      _showSnackBar('این متن رمزنگاری شده است. رمز عبور وارد کنید');
      return;
    }
    
    if (!TextConverter.isEncoded(input)) {
      _showSnackBar('متن وارد شده قابل بازسازی نیست');
      return;
    }
    
    final result = TextConverter.decode(
      input,
      password: needsPassword ? _decodePasswordController.text : null,
    );
    if (result.isEmpty) {
      _showSnackBar('خطا در بازسازی متن');
      return;
    }
    
    setState(() {
      _decodeResult = result;
    });
  }

  void _copyToClipboard(String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('کپی شد');
  }

  void _pasteFromClipboard(TextEditingController controller) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      controller.text = data!.text!;
      setState(() {});
    }
  }

  void _clear(TextEditingController controller, bool isEncode) {
    controller.clear();
    setState(() {
      if (isEncode) {
        _encodeResults = [];
        _estimatedParts = 1;
      } else {
        _decodeResult = '';
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('متن‌یار'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'تبدیل', icon: Icon(Icons.transform)),
              Tab(text: 'بازسازی', icon: Icon(Icons.restore)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildEncodeTab(),
            _buildDecodeTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildEncodeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // راهنما
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, 
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'متن دلخواه خود را وارد کنید تا به متن فارسی تبدیل شود',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // ورودی
          TextField(
            controller: _encodeController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'متن ورودی...',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.paste),
                    onPressed: () => _pasteFromClipboard(_encodeController),
                    tooltip: 'پیست',
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _clear(_encodeController, true),
                    tooltip: 'پاک کردن',
                  ),
                ],
              ),
            ),
            onChanged: (_) {
              setState(() {});
              _updateEstimate();
            },
          ),
          const SizedBox(height: 16),

          // انتخاب تعداد پیامک
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // انتخاب حالت خروجی
                  Row(
                    children: [
                      const Icon(Icons.text_fields, size: 20),
                      const SizedBox(width: 8),
                      const Text('حالت خروجی:', style: TextStyle(fontSize: 13)),
                      const Spacer(),
                      DropdownButton<OutputMode>(
                        value: _outputMode,
                        isDense: true,
                        underline: Container(),
                        borderRadius: BorderRadius.circular(8),
                        items: const [
                          DropdownMenuItem(
                            value: OutputMode.compact,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.compress, size: 16),
                                SizedBox(width: 6),
                                Text('فشرده', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: OutputMode.stealth,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility_off, size: 16),
                                SizedBox(width: 6),
                                Text('کلمه‌ای', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: OutputMode.natural,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.article, size: 16),
                                SizedBox(width: 6),
                                Text('طبیعی', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: OutputMode.encrypted,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock, size: 16),
                                SizedBox(width: 6),
                                Text('رمزی', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (OutputMode? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _outputMode = newValue;
                            });
                            _updateEstimate();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _outputMode == OutputMode.compact 
                      ? 'کوتاه‌تر - حروف فارسی بدون فاصله'
                      : _outputMode == OutputMode.stealth
                        ? '🕵️ شبیه متن عادی'
                        : _outputMode == OutputMode.natural
                          ? 'شبیه متن واقعی - کلمات فارسی با فاصله'
                          : 'رمزنگاری شده - نیاز به رمز عبور',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  
                  // فیلد رمز عبور (فقط در حالت رمزنگاری)
                  if (_outputMode == OutputMode.encrypted) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'رمز عبور',
                        hintText: 'رمز عبور را وارد کنید',
                        prefixIcon: const Icon(Icons.key, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                  const Divider(),
                  // سوئیچ بهینه‌سازی لینک
                  Row(
                    children: [
                      const Icon(Icons.link, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'بهینه‌سازی لینک',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      Switch(
                        value: _optimizeLinks,
                        onChanged: (value) {
                          setState(() {
                            _optimizeLinks = value;
                          });
                          _updateEstimate();
                        },
                      ),
                    ],
                  ),
                  if (_optimizeLinks)
                    const Text(
                      'برای لینک‌های اینترنتی فعال کنید',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  const Divider(),
                  Row(
                    children: [
                      const Icon(Icons.sms, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'تعداد پیامک: $_selectedParts',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      if (_estimatedParts > 1)
                        Text(
                          '(پیشنهادی: $_estimatedParts)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _selectedParts.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _selectedParts.toString(),
                    onChanged: (value) {
                      setState(() {
                        _selectedParts = value.round();
                      });
                    },
                  ),
                  const Text(
                    'هر پیامک فارسی حدود ۷۰ کاراکتر جا دارد',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // دکمه تبدیل
          ElevatedButton.icon(
            onPressed: _encodeController.text.isNotEmpty ? _encode : null,
            icon: const Icon(Icons.transform),
            label: const Text('تبدیل'),
          ),
          const SizedBox(height: 16),
          
          // نتایج (چند پیامک)
          if (_encodeResults.isNotEmpty) ...[
            Text(
              'نتیجه (${_encodeResults.length} پیامک):',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ..._encodeResults.asMap().entries.map((entry) {
              final index = entry.key;
              final text = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'پیامک ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${text.length} حرف',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: text.length > 70 
                                    ? Colors.orange 
                                    : Colors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                onPressed: () => _copyToClipboard(text),
                                tooltip: 'کپی',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        text,
                        style: const TextStyle(fontSize: 13, height: 1.6),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildDecodeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // راهنما
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, 
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'متن تبدیل شده را وارد کنید تا به متن اولیه بازسازی شود',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // ورودی
          TextField(
            controller: _decodeController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'متن تبدیل شده...',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.paste),
                    onPressed: () => _pasteFromClipboard(_decodeController),
                    tooltip: 'پیست',
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _clear(_decodeController, false),
                    tooltip: 'پاک کردن',
                  ),
                ],
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          
          // فیلد رمز عبور برای متن‌های رمزنگاری شده
          if (TextConverter.isEncryptedText(_decodeController.text)) ...[
            TextField(
              controller: _decodePasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'رمز عبور',
                hintText: 'این متن رمزنگاری شده است',
                prefixIcon: const Icon(Icons.key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // دکمه بازسازی
          ElevatedButton.icon(
            onPressed: _decodeController.text.isNotEmpty ? _decode : null,
            icon: const Icon(Icons.restore),
            label: const Text('بازسازی'),
          ),
          const SizedBox(height: 16),
          
          // نتیجه
          if (_decodeResult.isNotEmpty) ...[
            Row(  
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'نتیجه:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyToClipboard(_decodeResult),
                  tooltip: 'کپی',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                _decodeResult,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.8,
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
