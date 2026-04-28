import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
  }

  // ── Gibberish detection (pure Dart, no AI needed) ─────────────────────────
  // ── Description validators (pure Dart, no AI needed) ──────────────────────

bool _isGibberish(String text) {
  if (text.trim().length < 3) return true;
  final letters = text.replaceAll(RegExp(r'[^a-zA-Z\u0900-\u097F]'), '');
  final ratio = letters.length / text.trim().length;
  if (ratio < 0.4) return true;
  final vowels = RegExp(r'[aeiouAEIOU]');
  if (!vowels.hasMatch(text)) return true;
  return false;
}

bool _isTooLong(String text) {
  // Count words by splitting on whitespace
  final wordCount = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  return wordCount > 500;
}

bool _isTooVague(String text) {
  final trimmed = text.trim().toLowerCase();
  if (trimmed.isEmpty) return false; // empty is handled by _isGibberish
  
  // Less than 4 words is too vague
  final words = trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.length < 4) return true;

  // If description consists mostly of filler/generic words, it's too vague
  const vagueWords = {
    'this', 'it', 'item', 'thing', 'stuff', 'object', 'product',
    'something', 'anything', 'some', 'the', 'a', 'an', 'my', 'old',
    'new', 'good', 'bad', 'ok', 'okay', 'fine', 'is', 'are', 'was',
    'i', 'have', 'got', 'get', 'want', 'need', 'donate', 'donating',
  };
  final meaningfulWords = words.where((w) => !vagueWords.contains(w)).length;
  // If fewer than 2 meaningful words, it's too vague
  return meaningfulWords < 2;
}

  /// Classifies the item in [imageFile].
  /// Blur detection is intentionally NOT done here — it is handled
  /// in UploadItemScreen via BlurDetectionService before this is called.
  Future<Map<String, dynamic>> classifyItem({
    required File imageFile,
    required String description,
  }) async {
    final imageBytes = await imageFile.readAsBytes();

    // ── STEP 1: Validate description ─────────────────────────────────────────
String descriptionWarning = '';

if (_isTooLong(description)) {
  descriptionWarning =
      'Your description is too long (over 500 words). Please keep it brief and focused on the item. We\'ll classify based on your image and a shorter description.';
} else if (_isGibberish(description)) {
  descriptionWarning =
      'Your description was unclear so we classified based on the image only.';
} else if (_isTooVague(description)) {
  descriptionWarning =
      'Your description is too vague (e.g. "this thing"). Try describing the item specifically — what it is, its condition, and any damage. We\'ll classify from the image for now.';
}

final effectiveDescription = descriptionWarning.isNotEmpty
    ? 'No valid description provided. Use image only.'
    : description;

    // ── STEP 2: Validate that the image shows a donate-able item ──────────
    // Note: we only ask Gemini to check if the photo shows a real donate-able
    // object. Blur detection is already done locally before reaching here.
    final imagePart = DataPart('image/jpeg', imageBytes);
    final promptText = '''
You are a visual AI classifier for a donation platform in India.
User description: "$effectiveDescription"

FIRST — check if this image shows a real, physical, donate-able item:
- If the image shows a face, person, animal, blank wall, floor, sky, screenshot,
  text document, or any non-donate-able scene, set "imageQuality" to "notitem".
- Otherwise set "imageQuality" to "good".

SECOND — if imageQuality is "good", classify the item using these STRICT RULES:
- condition: Broken/cracked/torn/damaged → "needs_repair". Used but intact → "fair". Like-new → "good".
- classification: needs_repair → "repairable". good/fair → "usable". Destroyed beyond use → "unsuitable".
- repairType: Only set if repairable, else always "none".
- category: Pick single best match from the list below.

If imageQuality is "notitem", still return the full JSON but set:
- itemName: "Not a Valid Item"
- classification: "unsuitable"
- condition: "fair"
- category: "other"
- all repair fields to empty / "none"
- summary: explain clearly why the image was rejected

Output ONLY a raw JSON object. No markdown. No code fences. Start with { end with }.

{
  "imageQuality": "good|notitem",
  "itemName": "specific name of item visible in image",
  "category": "furniture|clothing|electronics|footwear|household|appliance|books|toys|other",
  "condition": "good|fair|needs_repair",
  "classification": "usable|repairable|unsuitable",
  "repairType": "carpenter|cobbler|technician|tailor|plumber|none",
  "repairDescription": "what needs fixing or empty string",
  "estimatedRepairTime": "e.g. 2 hours or empty string",
  "donationSuitability": "high|medium|low",
  "summary": "Two clear sentences: what you see and your recommendation.",
  "suggestedNgoCategory": "type of NGO best suited for this item"
}
''';

    try {
      final response = await _model.generateContent([
        Content.multi([imagePart, TextPart(promptText)])
      ]);

      final text = response.text ?? '';
      debugPrint('Gemini raw response: $text');

      if (text.isEmpty) {
        return _fallbackClassification(description, descriptionWarning);
      }

      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) {
        return _fallbackClassification(description, descriptionWarning);
      }

      final decoded =
          jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;

      final imageQuality =
          (decoded['imageQuality'] ?? 'good').toString().toLowerCase();

      String inputWarning = '';
      if (imageQuality == 'notitem') {
        inputWarning =
            'This does not appear to be a donate-able item. Please photograph the actual item you wish to donate.';
      }

      // ── Enforce condition → classification consistency ──────────────────
      if (imageQuality == 'good') {
        final condition = (decoded['condition'] ?? '').toString();
        if (condition == 'needs_repair') {
          decoded['classification'] = 'repairable';
        } else if ((condition == 'good' || condition == 'fair') &&
            decoded['classification'] == 'repairable') {
          decoded['classification'] = 'usable';
        }
        if (decoded['classification'] != 'repairable') {
          decoded['repairType'] = 'none';
          decoded['repairDescription'] = '';
        }
      }

      decoded['inputWarning'] = inputWarning;
      decoded['descriptionWarning'] = descriptionWarning;

      debugPrint('Final result: $decoded');
      return decoded;
    } catch (e, stack) {
      debugPrint('Gemini classifyItem error: $e\n$stack');
      return _fallbackClassification(description, descriptionWarning);
    }
  }

  Future<Map<String, dynamic>> analyzeResource({
    required File imageFile,
    required String voiceNote,
  }) async {
    final result = await classifyItem(
      imageFile: imageFile,
      description: voiceNote,
    );

    return {
      'materialType': result['itemName'] ?? 'Unknown Item',
      'quantity': '1 unit',
      'condition': result['condition'] ?? 'fair',
      'estimatedValue': 0,
      'category': result['category'] ?? 'other',
      'classification': result['classification'] ?? 'usable',
      'repairType': result['repairType'] ?? 'none',
      'repairDescription': result['repairDescription'] ?? '',
      'summary': result['summary'] ?? '',
      'primaryMatch': {
        'type': 'ngo',
        'reason': result['suggestedNgoCategory'] ?? 'Nearest NGO',
        'distance': 'nearby',
        'earning': 0,
      },
      'resourceChain': [
        {
          'step': 1,
          'actor': 'NGO',
          'action': 'Receives and distributes item',
          'earning': 0
        }
      ],
      'impactScore': {
        'wasteReduced': '1 item',
        'co2Saved': '0 kg',
        'incomeGenerated': 0
      },
      ...result,
    };
  }

  Future<Map<String, dynamic>> recommendNGOMatch({
    required String itemName,
    required String category,
    required String condition,
    required List<Map<String, dynamic>> availableNGOs,
  }) async {
    if (availableNGOs.isEmpty) {
      return {
        'bestMatchIndex': 0,
        'matchReason': 'No NGOs available',
        'matchScore': 0
      };
    }

    final ngoList = availableNGOs
        .map((n) => '${n['name']} (accepts: ${n['categories']})')
        .join('\n');

    final promptText = '''
You are a resource matching AI for Resource Bridge.
Item: $itemName, Category: $category, Condition: $condition
Available NGOs:
$ngoList
Best match? Respond ONLY with raw JSON starting with {:
{"bestMatchIndex":0,"matchReason":"brief explanation","matchScore":85,"alternativeIndex":1}
''';

    try {
      final response =
          await _model.generateContent([Content.text(promptText)]);
      final text = response.text ?? '';
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start == -1 || end == -1) {
        return {
          'bestMatchIndex': 0,
          'matchReason': 'Best available NGO',
          'matchScore': 70
        };
      }
      return jsonDecode(text.substring(start, end + 1))
          as Map<String, dynamic>;
    } catch (e) {
      return {
        'bestMatchIndex': 0,
        'matchReason': 'Best available NGO',
        'matchScore': 70
      };
    }
  }

  Map<String, dynamic> _fallbackClassification(
      String description, String descriptionWarning) {
    final desc = description.toLowerCase();
    final isRepair = desc.contains('broken') ||
        desc.contains('damaged') ||
        desc.contains('crack') ||
        desc.contains('torn') ||
        desc.contains('fix') ||
        desc.contains('repair');

    return {
      'imageQuality': 'good',
      'itemName': description.isNotEmpty ? description : 'Unknown Item',
      'category': 'other',
      'condition': isRepair ? 'needs_repair' : 'fair',
      'classification': isRepair ? 'repairable' : 'usable',
      'repairType': isRepair ? 'technician' : 'none',
      'repairDescription': isRepair ? 'Repair needed as described' : '',
      'estimatedRepairTime': '',
      'donationSuitability': 'medium',
      'summary':
          'Item submitted for review. Manual classification may be needed.',
      'suggestedNgoCategory': 'general',
      'materialType': description,
      'quantity': '1 unit',
      'estimatedValue': 0,
      'inputWarning': '',
      'descriptionWarning': descriptionWarning,
    };
  }
}