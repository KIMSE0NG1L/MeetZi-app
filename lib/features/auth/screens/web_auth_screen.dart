import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:nearo_app/shared/utils/token_storage.dart';

class WebAuthScreen extends StatefulWidget {
  final String initialUrl;

  const WebAuthScreen({super.key, required this.initialUrl});

  @override
  State<WebAuthScreen> createState() => _WebAuthScreenState();
}

class _WebAuthScreenState extends State<WebAuthScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    print('🔵 WebAuthScreen 시작: ${widget.initialUrl}');
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            print('✅ 페이지 로드 완료: $url');
          },
          onWebResourceError: (error) {
            print('❌ 웹뷰 오류: ${error.description}');
            print('   오류 코드: ${error.errorCode}');
            print('   URL: ${error.url}');
          },
          onNavigationRequest: (request) {
            print('🔄 네비게이션: ${request.url}');
            final uri = Uri.parse(request.url);
            // custom scheme: nearo://auth?token=...
            if (uri.scheme == 'nearo' && uri.host == 'auth') {
              final token = uri.queryParameters['token'];
              print('🎉 토큰 수신: $token');
              if (token != null && token.isNotEmpty) {
                // 저장 후 환경 선택 화면으로 이동
                TokenStorage().saveAccessToken(token);
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/environment');
                }
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    _prepareWebView();
  }

  Future<void> _prepareWebView() async {
    final cookieManager = WebViewCookieManager();
    await cookieManager.clearCookies();
    await _controller.clearCache();
    await _controller.loadRequest(Uri.parse(widget.initialUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
