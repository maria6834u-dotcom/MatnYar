import 'dart:convert';
import 'dart:io';

/// نوع خروجی تبدیل
enum OutputMode {
  compact,  // فشرده - حروف فارسی
  natural,  // طبیعی - کلمات فارسی
}

/// کلاس تبدیل متن
/// متن ورودی را به متن فارسی خوانا تبدیل می‌کند و برعکس
/// این یک ابزار آموزشی برای نمایش مفاهیم تبدیل و بازیابی داده است
class TextConverter {
  // 16 حرف فارسی برای nibble encoding (هر بایت = 2 حرف)
  static const List<String> _nibbles = [
    'ا', 'ب', 'پ', 'ت', 'ث', 'ج', 'چ', 'ح',
    'خ', 'د', 'ذ', 'ر', 'ز', 'س', 'ش', 'ص',
  ];

  // 256 کلمه فارسی برای حالت طبیعی
  static const List<String> _words = [
    'من', 'تو', 'او', 'ما', 'شما', 'آن', 'این', 'که',
    'وی', 'یا', 'با', 'از', 'به', 'در', 'تا', 'بر',
    'چه', 'کی', 'کو', 'نه', 'ها', 'هم', 'پس', 'بس',
    'آه', 'اگر', 'جز', 'مگر', 'یک', 'دو', 'سه', 'ده',
    'سر', 'پا', 'دل', 'تن', 'رو', 'لب', 'چشم', 'گوش',
    'مو', 'دم', 'پر', 'بال', 'شاخ', 'پوست', 'رگ', 'خون',
    'پدر', 'مادر', 'زن', 'فوت', 'پسر', 'دختر', 'بچه', 'نوه',
    'عمو', 'خاله', 'دایی', 'عمه', 'داماد', 'عروس', 'یار', 'دوست',
    'آب', 'باد', 'خاک', 'آتش', 'سنگ', 'کوه', 'دشت', 'جنگل',
    'رود', 'دریا', 'چشمه', 'ابر', 'برف', 'باران', 'مه', 'شبنم',
    'گل', 'برگ', 'شاخه', 'ریشه', 'تنه', 'میوه', 'دانه', 'علف',
    'مرغ', 'ماهی', 'گربه', 'سگ', 'اسب', 'گاو', 'گوسفند', 'ببر',
    'رفت', 'آمد', 'گفت', 'دید', 'شد', 'بود', 'داد', 'کرد',
    'زد', 'خورد', 'برد', 'آورد', 'ریخت', 'سوخت', 'شکست', 'بست',
    'باز', 'بسته', 'خواند', 'نوشت', 'کشید', 'ساخت', 'پخت', 'دوخت',
    'شست', 'مرد', 'زاد', 'ماند', 'نشست', 'خفت', 'خیز', 'افتاد',
    'خوب', 'بد', 'نو', 'کهنه', 'پیر', 'جوان', 'زنده', 'مرده',
    'گرم', 'سرد', 'تر', 'خشک', 'نرم', 'سخت', 'تند', 'کند',
    'بلند', 'کوته', 'پهن', 'باریک', 'سبک', 'سنگین', 'پرپر', 'خالی',
    'روشن', 'تیره', 'سیاه', 'سفید', 'سرخ', 'زرد', 'سبز', 'آبی',
    'نان', 'آش', 'چای', 'دوغ', 'گوشت', 'برنج', 'نمک', 'روغن',
    'دری', 'دیوار', 'سقف', 'کف', 'پله', 'راه', 'کوچه', 'بازار',
    'کتاب', 'قلم', 'کاغذ', 'میز', 'صندلی', 'تخت', 'فرش', 'پرده',
    'لباس', 'کفش', 'کلاه', 'عینک', 'ساعت', 'کیف', 'چتر', 'کلید',
    'روز', 'شب', 'صبح', 'ظهر', 'عصر', 'فردا', 'دیروز', 'امروز',
    'سال', 'ماه', 'هفته', 'دقیقه', 'لحظه', 'وقت', 'زمان', 'مکان',
    'کار', 'درس', 'بازی', 'خواب', 'خنده', 'گریه', 'حرف', 'سکوت',
    'عشق', 'دوستی', 'امید', 'ترس', 'غم', 'شادی', 'درد', 'صبر',
    'علی', 'رضا', 'حسن', 'حسین', 'محمد', 'احمد', 'مهدی', 'امیر',
    'زهرا', 'فاطمه', 'مریم', 'سارا', 'نازی', 'مینا', 'لیلا', 'نگار',
    'پدرام', 'بهرام', 'کامران', 'فرهاد', 'شهرام', 'پیمان', 'آرش', 'کیان',
    'پریسا', 'نسترن', 'سپیده', 'شیدا', 'ندا', 'هدی', 'آیدا', 'سمیرا',
  ];

  // اعداد فارسی برای شماره‌گذاری
  static const List<String> _persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

  /// تبدیل عدد به رقم فارسی
  static String _toPersianNumber(int n) {
    return n.toString().split('').map((d) => _persianDigits[int.parse(d)]).join();
  }

  /// تبدیل متن به متن فارسی - برمی‌گرداند لیست پیام‌ها
  /// [parts] تعداد قسمت‌ها (پیامک‌ها) - اگر 1 باشد همه در یک پیام
  /// [optimize] بهینه‌سازی متن قبل از تبدیل
  /// [mode] حالت خروجی - فشرده یا طبیعی
  static List<String> encode(String input, {int parts = 1, bool optimize = false, OutputMode mode = OutputMode.compact}) {
    if (input.isEmpty) return [''];

    try {
      // پیش‌پردازش برای فشرده‌سازی بهتر
      String processed = optimize ? _preprocess(input) : input;
      
      // فشرده‌سازی با سطح بالا
      final bytes = utf8.encode(processed);
      final codec = ZLibCodec(level: 9);
      final compressed = codec.encode(bytes);

      String encoded;
      if (mode == OutputMode.natural) {
        // حالت طبیعی - کلمات فارسی
        final words = <String>[];
        for (int i = 0; i < compressed.length; i++) {
          words.add(_words[compressed[i]]);
        }
        encoded = words.join(' ');
      } else {
        // حالت فشرده - حروف فارسی
        final buffer = StringBuffer();
        for (int i = 0; i < compressed.length; i++) {
          final b = compressed[i];
          buffer.write(_nibbles[b >> 4]);
          buffer.write(_nibbles[b & 0x0F]);
        }
        encoded = buffer.toString();
      }

      // اگر فقط یک قسمت خواسته
      if (parts <= 1) {
        return [encoded];
      }

      // تقسیم به چند قسمت
      if (mode == OutputMode.natural) {
        // برای حالت طبیعی بر اساس کلمات تقسیم کن
        final wordList = encoded.split(' ');
        final wordsPerPart = (wordList.length / parts).ceil();
        final result = <String>[];

        for (int i = 0; i < parts; i++) {
          final start = i * wordsPerPart;
          if (start >= wordList.length) break;
          
          final end = (start + wordsPerPart).clamp(0, wordList.length);
          final partWords = wordList.sublist(start, end);
          
          final partNum = _toPersianNumber(i + 1);
          final totalNum = _toPersianNumber(parts);
          result.add('[$partNum/$totalNum] ${partWords.join(' ')}');
        }
        return result;
      } else {
        // برای حالت فشرده بر اساس حروف تقسیم کن
        final charsPerPart = (encoded.length / parts).ceil();
        final adjustedCharsPerPart = charsPerPart + (charsPerPart % 2);
        final result = <String>[];

        for (int i = 0; i < parts; i++) {
          final start = i * adjustedCharsPerPart;
          if (start >= encoded.length) break;
          
          final end = (start + adjustedCharsPerPart).clamp(0, encoded.length);
          final partText = encoded.substring(start, end);
          
          final partNum = _toPersianNumber(i + 1);
          final totalNum = _toPersianNumber(parts);
          result.add('[$partNum/$totalNum]$partText');
        }
        return result;
      }
    } catch (e) {
      return [_encodeFallback(input, mode)];
    }
  }

  /// پیش‌پردازش متن برای فشرده‌سازی بهینه‌تر
  /// این تابع الگوهای رایج متنی را ساده می‌کند
  static String _preprocess(String input) {
    String result = input;
    
    // تبدیل کدهای درصدی به کاراکتر اصلی
    result = Uri.decodeFull(result);
    
    // الگوهای رایج پروتکلی
    result = result.replaceAll('vless://', '¹');
    result = result.replaceAll('vmess://', '²');
    result = result.replaceAll('trojan://', '³');
    result = result.replaceAll('ss://', '⁴');
    result = result.replaceAll('https://', '⁵');
    result = result.replaceAll('http://', '⁶');
    
    // الگوهای رایج پارامتری
    result = result.replaceAll('security=tls', '⁷');
    result = result.replaceAll('encryption=none', '⁸');
    result = result.replaceAll('type=ws', '⁹');
    result = result.replaceAll('type=tcp', '⁰');
    result = result.replaceAll('fp=randomized', 'ᵃ');
    result = result.replaceAll('fp=chrome', 'ᵇ');
    result = result.replaceAll('fp=firefox', 'ᶜ');
    result = result.replaceAll('allowInsecure=1', 'ᵈ');
    result = result.replaceAll('allowInsecure=0', 'ᵉ');
    
    // ساده‌سازی جداکننده‌ها
    result = result.replaceAll('path=/', 'ᶠ');
    result = result.replaceAll('host=', 'ᵍ');
    result = result.replaceAll('sni=', 'ʰ');
    result = result.replaceAll('?ed=', 'ⁱ');
    result = result.replaceAll('www.', '');
    
    // حذف توضیحات انتهای متن (بعد از #)
    final hashIndex = result.lastIndexOf('#');
    if (hashIndex > 0) {
      result = result.substring(0, hashIndex);
    }
    
    return result;
  }

  /// بازگرداندن پیش‌پردازش
  static String _postprocess(String input) {
    String result = input;
    
    // بازگرداندن پروتکل‌ها
    result = result.replaceAll('¹', 'vless://');
    result = result.replaceAll('²', 'vmess://');
    result = result.replaceAll('³', 'trojan://');
    result = result.replaceAll('⁴', 'ss://');
    result = result.replaceAll('⁵', 'https://');
    result = result.replaceAll('⁶', 'http://');
    
    // بازگرداندن پارامترها
    result = result.replaceAll('⁷', 'security=tls');
    result = result.replaceAll('⁸', 'encryption=none');
    result = result.replaceAll('⁹', 'type=ws');
    result = result.replaceAll('⁰', 'type=tcp');
    result = result.replaceAll('ᵃ', 'fp=randomized');
    result = result.replaceAll('ᵇ', 'fp=chrome');
    result = result.replaceAll('ᶜ', 'fp=firefox');
    result = result.replaceAll('ᵈ', 'allowInsecure=1');
    result = result.replaceAll('ᵉ', 'allowInsecure=0');
    
    // بازگرداندن جداکننده‌ها
    result = result.replaceAll('ᶠ', 'path=/');
    result = result.replaceAll('ᵍ', 'host=');
    result = result.replaceAll('ʰ', 'sni=');
    result = result.replaceAll('ⁱ', '?ed=');
    
    return result;
  }

  /// تخمین تعداد پیامک مورد نیاز
  static int estimateParts(String input, {int maxCharsPerPart = 60, bool optimize = false, OutputMode mode = OutputMode.compact}) {
    if (input.isEmpty) return 1;
    
    try {
      // اعمال پیش‌پردازش برای تخمین دقیق‌تر
      final processed = optimize ? _preprocess(input) : input;
      final bytes = utf8.encode(processed);
      final codec = ZLibCodec(level: 9);
      final compressed = codec.encode(bytes);
      
      int estimatedLength;
      if (mode == OutputMode.natural) {
        // حالت طبیعی: هر بایت = یک کلمه (میانگین 4 حرف + 1 فاصله)
        estimatedLength = compressed.length * 5;
      } else {
        // حالت فشرده: هر بایت = 2 حرف فارسی
        estimatedLength = compressed.length * 2;
      }
      return (estimatedLength / maxCharsPerPart).ceil().clamp(1, 10);
    } catch (e) {
      return 3;
    }
  }

  /// بازسازی متن از یک یا چند قسمت
  /// می‌تواند لیست پیام‌ها یا یک پیام واحد را بگیرد
  static String decode(dynamic input) {
    if (input == null) return '';
    
    String fullText;
    
    if (input is List<String>) {
      // اگر لیست پیام‌ها باشد، مرتب‌سازی و ترکیب
      fullText = _combineMessages(input);
    } else if (input is String) {
      fullText = input;
    } else {
      return '';
    }

    if (fullText.isEmpty) return '';

    try {
      // حذف شماره‌گذاری [۱/۳] اگر وجود داشت
      fullText = fullText.replaceAll(RegExp(r'\[[\d۰-۹]+/[\d۰-۹]+\]\s*'), '');
      
      // تشخیص حالت: اگر کلمات فارسی داشت = طبیعی، وگرنه = فشرده
      final isNaturalMode = _detectMode(fullText) == OutputMode.natural;
      
      List<int> bytes;
      if (isNaturalMode) {
        // حالت طبیعی - کلمات فارسی
        final words = fullText.split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .toList();
        bytes = <int>[];
        for (final word in words) {
          final index = _words.indexOf(word);
          if (index != -1) {
            bytes.add(index);
          }
        }
      } else {
        // حالت فشرده - حروف فارسی
        final validChars = fullText.split('').where((c) => _nibbles.contains(c)).toList();
        bytes = <int>[];
        for (int i = 0; i < validChars.length - 1; i += 2) {
          final high = _nibbles.indexOf(validChars[i]);
          final low = _nibbles.indexOf(validChars[i + 1]);
          if (high == -1 || low == -1) continue;
          bytes.add((high << 4) | low);
        }
      }

      // decompress
      final codec = ZLibCodec(level: 9);
      final decompressed = codec.decode(bytes);

      // بازگرداندن پیش‌پردازش و برگرداندن متن اصلی
      final decoded = utf8.decode(decompressed);
      return _postprocess(decoded);
    } catch (e) {
      return '';
    }
  }

  /// تشخیص حالت متن (فشرده یا طبیعی)
  static OutputMode _detectMode(String input) {
    // اگر فاصله داره، احتمالا حالت طبیعیه
    if (input.contains(' ')) {
      final words = input.split(RegExp(r'\s+'));
      int wordMatch = 0;
      for (final word in words.take(15)) {
        if (_words.contains(word)) wordMatch++;
      }
      // اگر حداقل 2 کلمه شناخته شده داشت = طبیعی
      if (wordMatch >= 2) return OutputMode.natural;
    }
    
    // بررسی حالت فشرده - فقط حروف nibble
    int nibbleMatch = 0;
    int total = 0;
    for (final char in input.split('')) {
      if (char.trim().isEmpty) continue;
      total++;
      if (_nibbles.contains(char)) nibbleMatch++;
    }
    // اگر بیشتر از 80% حروف nibble باشه = فشرده
    if (total > 0 && nibbleMatch / total > 0.8) return OutputMode.compact;
    
    // اگر فاصله نداره ولی nibble هم نیست، شاید طبیعی بدون فاصله باشه
    // سعی کن کلمات رو پیدا کنی
    for (final word in _words) {
      if (input.contains(word)) return OutputMode.natural;
    }
    
    return OutputMode.compact;
  }

  /// ترکیب چند پیام با ترتیب صحیح
  static String _combineMessages(List<String> messages) {
    if (messages.isEmpty) return '';
    if (messages.length == 1) return messages.first;

    // استخراج شماره هر پیام و مرتب‌سازی
    final numbered = <int, String>{};
    final unnumbered = <String>[];

    final partPattern = RegExp(r'^\[([\d۰-۹]+)/([\d۰-۹]+)\](.*)$');

    for (final msg in messages) {
      final match = partPattern.firstMatch(msg.trim());
      if (match != null) {
        final partNum = _parsePersianNumber(match.group(1)!);
        numbered[partNum] = match.group(3)!;
      } else {
        unnumbered.add(msg);
      }
    }

    // مرتب‌سازی و ترکیب
    if (numbered.isNotEmpty) {
      final sortedKeys = numbered.keys.toList()..sort();
      final combined = sortedKeys.map((k) => numbered[k]!.trim()).toList();
      // اگر حالت طبیعی باشد با فاصله، وگرنه بدون فاصله
      final first = combined.first;
      final isNatural = first.contains(' ') || _words.any((w) => first.startsWith(w));
      return combined.join(isNatural ? ' ' : '');
    }

    return unnumbered.join(' ');
  }

  /// تبدیل رقم فارسی به عدد
  static int _parsePersianNumber(String s) {
    String result = s;
    for (int i = 0; i < _persianDigits.length; i++) {
      result = result.replaceAll(_persianDigits[i], i.toString());
    }
    return int.tryParse(result) ?? 0;
  }

  /// تشخیص اینکه متن قابل بازسازی است
  static bool isEncoded(String input) {
    if (input.isEmpty) return false;
    
    // حذف شماره‌گذاری
    final cleaned = input.replaceAll(RegExp(r'\[[\d۰-۹]+/[\d۰-۹]+\]\s*'), '');
    
    // بررسی حالت طبیعی
    final words = cleaned.split(RegExp(r'\s+'));
    int wordMatch = 0;
    for (final word in words.take(10)) {
      if (_words.contains(word)) wordMatch++;
    }
    if (wordMatch >= 3) return true;
    
    // بررسی حالت فشرده
    int nibbleMatch = 0;
    int totalCount = 0;
    for (final char in cleaned.split('')) {
      if (_nibbles.contains(char)) nibbleMatch++;
      if (char.trim().isNotEmpty) totalCount++;
    }
    return totalCount > 0 && nibbleMatch / totalCount > 0.7;
  }

  /// تشخیص شماره قسمت از پیام
  static (int part, int total)? getPartInfo(String message) {
    final pattern = RegExp(r'^\[([\d۰-۹]+)/([\d۰-۹]+)\]');
    final match = pattern.firstMatch(message.trim());
    if (match != null) {
      return (_parsePersianNumber(match.group(1)!), _parsePersianNumber(match.group(2)!));
    }
    return null;
  }

  // Fallback برای حالت‌های خاص
  static String _encodeFallback(String input, OutputMode mode) {
    final bytes = utf8.encode(input);
    final buffer = StringBuffer();

    if (mode == OutputMode.natural) {
      for (int i = 0; i < bytes.length; i++) {
        buffer.write(_words[bytes[i] % 256]);
        if (i < bytes.length - 1) buffer.write(' ');
      }
    } else {
      for (int i = 0; i < bytes.length; i++) {
        final b = bytes[i];
        buffer.write(_nibbles[b >> 4]);
        buffer.write(_nibbles[b & 0x0F]);
      }
    }

    return buffer.toString();
  }
}

