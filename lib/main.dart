import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img;

void main() => runApp(DuppliFilterApp());

class DuppliFilterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DuppliFilter',
      home: DuppliFilterHome(),
    );
  }
}

class DuppliFilterHome extends StatefulWidget {
  @override
  _DuppliFilterHomeState createState() => _DuppliFilterHomeState();
}

class _DuppliFilterHomeState extends State<DuppliFilterHome> {
  List<PlatformFile> images = [];
  List<PlatformFile> filteredImages = [];
  int duplicatesFound = 0;

  Future<void> pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        images = result.files;
        filteredImages = [];
        duplicatesFound = 0;
      });
      analyzeImages();
    }
  }

  Future<void> analyzeImages() async {
    List<PlatformFile> uniques = [];
    List<PlatformFile> dups = [];

    for (var img1 in images) {
      final bytes1 = await File(img1.path!).readAsBytes();
      final decoded1 = img.decodeImage(bytes1) ?? img.Image(1, 1);
      final resized1 = img.copyResize(decoded1, width: 64, height: 64);

      bool isDuplicate = false;

      for (var img2 in uniques) {
        final bytes2 = await File(img2.path!).readAsBytes();
        final decoded2 = img.decodeImage(bytes2) ?? img.Image(1, 1);
        final resized2 = img.copyResize(decoded2, width: 64, height: 64);

        double diff = _imageDiff(resized1, resized2);
        if (diff < 8.0) {
          isDuplicate = true;
          break;
        }
      }

      if (!isDuplicate) {
        uniques.add(img1);
      } else {
        dups.add(img1);
      }
    }

    setState(() {
      filteredImages = uniques;
      duplicatesFound = dups.length;
    });
  }

  double _imageDiff(img.Image a, img.Image b) {
    int sum = 0;
    for (int y = 0; y < a.height; y++) {
      for (int x = 0; x < a.width; x++) {
        int p1 = a.getPixel(x, y);
        int p2 = b.getPixel(x, y);
        int diff = ((img.getLuminance(p1) - img.getLuminance(p2)).abs());
        sum += diff;
      }
    }
    return sum / (a.width * a.height);
  }

  void shareImages(List<PlatformFile> files) {
    final paths = files.map((f) => f.path!).toList();
    Share.shareFiles(paths);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('DuppliFilter')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickImages,
              child: Text('Seleziona immagini'),
            ),
            if (duplicatesFound > 0)
              Column(
                children: [
                  SizedBox(height: 20),
                  Text(
                    'Trovate \$duplicatesFound immagini troppo simili.',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text('Vuoi filtrare prima dell\'invio?'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => shareImages(images),
                        child: Text('Invia tutte'),
                      ),
                      TextButton(
                        onPressed: () => shareImages(filteredImages),
                        child: Text('Filtra e invia'),
                      ),
                    ],
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }
}