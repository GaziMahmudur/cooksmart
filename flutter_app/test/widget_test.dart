import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cooksmart/main.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    HttpOverrides.global = _TestHttpOverrides();
  });

  testWidgets('CookSmart app loads and renders main UI elements', (WidgetTester tester) async {
    await tester.pumpWidget(const CookSmartApp());
    await tester.pump();

    // Verify title / header text
    expect(find.text('Good evening, Chef! 👋'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Pantry'), findsOneWidget);
    expect(find.text('Ask Chef'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);

    // Tap Pantry tab
    await tester.tap(find.text('Pantry'));
    await tester.pump();

    // Verify Pantry screen elements
    expect(find.text('Smart Pantry'), findsOneWidget);
    expect(find.text('Make Recipe with Gemini AI'), findsOneWidget);

    // Tap Ask Chef tab
    await tester.tap(find.text('Ask Chef'));
    await tester.pump();

    // Verify Ask Chef screen elements
    expect(find.text('Ask AI Chef'), findsWidgets);

    // Tap Saved tab
    await tester.tap(find.text('Saved'));
    await tester.pump();

    // Verify Saved screen elements
    expect(find.text('Saved Recipes'), findsOneWidget);
  });

  testWidgets('CookSmart app toggles language between English and Bangla', (WidgetTester tester) async {
    await tester.pumpWidget(const CookSmartApp());
    await tester.pump();

    // Verify initial English
    expect(find.text('Good evening, Chef! 👋'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('বাংলা'), findsOneWidget);

    // Tap language toggle pill
    await tester.tap(find.text('বাংলা'));
    await tester.pump();

    // Verify Bangla texts
    expect(find.text('শুভ সন্ধ্যা, শেফ! 👋'), findsOneWidget);
    expect(find.text('হোম'), findsOneWidget);
    expect(find.text('প্যান্ট্রি'), findsOneWidget);
    expect(find.text('এআই শেফ'), findsOneWidget);
    expect(find.text('সংরক্ষিত'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    // Tap language toggle pill again to return to English
    await tester.tap(find.text('English'));
    await tester.pump();

    // Verify English restored
    expect(find.text('Good evening, Chef! 👋'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient();
  }
}

class _FakeHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _FakeHttpClientRequest();
  }
}

class _FakeHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return _FakeHttpClientResponse();
  }
}

class _FakeHttpHeaders extends Fake implements HttpHeaders {}

class _FakeHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentPixel.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentPixel]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

const List<int> _transparentPixel = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];



