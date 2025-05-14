import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'AIzaSyBHgfTUPyIBbayKiYQ-LCBb4GLiDGp4370';
  static const String _model = 'gemini-2.0-flash';

  static Future<String> getResponse(String prompt) async {
    final lowerPrompt = prompt.toLowerCase();
    if (lowerPrompt.contains('sen kimsin') ||
        lowerPrompt.contains('adın ne') ||
        lowerPrompt.contains('kim') ||
        lowerPrompt.contains('nesin') ||
        lowerPrompt.contains('ne yapıyorsun')) {
      return 'Ben <b>Eleştir-AI</b>\'yim. Size problemlerinizde yardımcı olmak için buradayım.';
    }

    final modifiedPrompt = '$prompt\n\nLütfen sadece kısa, öz, temiz <b>HTML</b> formatında cevap ver. Kod bloğu veya ``` kullanma.';

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": modifiedPrompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '⚠️ Boş cevap döndü.';

        // Kod bloğu varsa temizle (``` veya ```html)
        text = text.replaceAll(RegExp(r'```html'), '').replaceAll('```', '');

        // Markdown -> HTML dönüştür
        text = _convertMarkdownToHtml(text);

        return text;
      } else if (response.statusCode == 429) {
        return '🚫 Aylık kota sınırına ulaştınız.';
      } else {
        return '❌ Hata ${response.statusCode}: ${response.reasonPhrase}\n\n${response.body}';
      }
    } catch (e) {
      return '❌ İstek sırasında hata: $e';
    }
  }

  static String _convertMarkdownToHtml(String text) {
    String html = text;
    html = html.replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (m) => '<b>${m[1]}</b>');
    html = html.replaceAll('* ', '<li>');
    if (html.contains('<li>')) {
      html = '<ul>$html</ul>';
    }
    return html;
  }
}
