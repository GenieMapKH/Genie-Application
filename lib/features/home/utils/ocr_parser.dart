import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrParser {
  static List<Map<String, dynamic>> parseRecognizedText(
    RecognizedText recognizedText,
  ) {
    List<Map<String, dynamic>> coordinates = [];

    // ML Kit structure: Blocks -> Lines -> Elements (Words)
    List<TextElement> allWords = [];
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        for (TextElement element in line.elements) {
          if (RegExp(r'\d').hasMatch(element.text)) {
            allWords.add(element);
          }
        }
      }
    }

    if (allWords.isNotEmpty) {
      // Group by Y
      List<List<TextElement>> rows = [];
      const double yTolerance = 25.0;

      for (var word in allWords) {
        bool placed = false;
        for (var row in rows) {
          double sumY = 0;
          for (var w in row) {
            sumY += w.boundingBox.top;
          }
          double avgY = sumY / row.length;

          if ((word.boundingBox.top - avgY).abs() < yTolerance) {
            row.add(word);
            placed = true;
            break;
          }
        }
        if (!placed) {
          rows.add([word]);
        }
      }
      // Sort rows from top to bottom based on their average Y coordinate
      rows.sort((a, b) {
        double avgYa =
            a.fold(0.0, (sum, w) => sum + w.boundingBox.top) / a.length;
        double avgYb =
            b.fold(0.0, (sum, w) => sum + w.boundingBox.top) / b.length;
        return avgYa.compareTo(avgYb);
      });

      for (var row in rows) {
        // Sort left to right
        row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

        List<double> cleanNumbers = [];
        for (var word in row) {
          String t = word.text
              .replaceAll(RegExp(r'[Ss]'), '5')
              .replaceAll(RegExp(r'[lI]'), '1')
              .replaceAll(RegExp(r'[Oo]'), '0')
              .replaceAll(',', '.');

          Iterable<RegExpMatch> matches = RegExp(
            r'\d+(?:\.\d+)?',
          ).allMatches(t);
          for (var m in matches) {
            double? num = double.tryParse(m.group(0)!);
            if (num != null) {
              if (num > 9999999) num = num / 1000;
              cleanNumbers.add(num);
            }
          }
        }

        if (cleanNumbers.length >= 2) {
          for (int i = 0; i < cleanNumbers.length - 1; i++) {
            double x = cleanNumbers[i];
            double y = cleanNumbers[i + 1];
            if (x > 100000 && x < 999999 && y > 1000000 && y < 9999999) {
              coordinates.add({'x': x, 'y': y});
              break; // Found one valid pair in this row
            }
          }
        }
      }
    }

    // Fallback: simple text parsing
    if (coordinates.isEmpty && recognizedText.text.isNotEmpty) {
      var lines = recognizedText.text.split('\n');
      for (var line in lines) {
        String t = line
            .replaceAll(RegExp(r'[Ss]'), '5')
            .replaceAll(RegExp(r'[lI]'), '1')
            .replaceAll(RegExp(r'[Oo]'), '0')
            .replaceAll(',', '.');

        Iterable<RegExpMatch> matches = RegExp(r'\d+(?:\.\d+)?').allMatches(t);
        List<double> nums = [];
        for (var m in matches) {
          double? num = double.tryParse(m.group(0)!);
          if (num != null) {
            if (num > 9999999) num = num / 1000;
            nums.add(num);
          }
        }
        if (nums.length >= 2) {
          for (int i = 0; i < nums.length - 1; i++) {
            double x = nums[i];
            double y = nums[i + 1];
            if (x > 100000 && x < 999999 && y > 1000000 && y < 9999999) {
              coordinates.add({'x': x, 'y': y});
              break;
            }
          }
        }
      }
    }

    return coordinates;
  }
}
