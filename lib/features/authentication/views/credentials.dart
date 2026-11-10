import 'package:bonfire/features/authentication/repositories/auth.dart';
import 'package:bonfire/theme/text_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewLoginScreen extends ConsumerStatefulWidget {
  const WebviewLoginScreen({
    super.key,
  });

  @override
  ConsumerState<WebviewLoginScreen> createState() => _WebviewLoginScreenState();
}

class _WebviewLoginScreenState extends ConsumerState<WebviewLoginScreen> {
  bool webviewInitialized = false;
  bool showTokenLogin = false;
  bool isSubmittingToken = false;
  String? tokenError;
  final tokenController = TextEditingController();
  final webviewController = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted);

  @override
  void dispose() {
    debugPrint("DISPOSING WEBVIEW");

    // widget.fireviewController.dispose();
    tokenController.dispose();
    super.dispose();
  }

  Future<void> _submitToken() async {
    final token = tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => tokenError = "Paste a token first.");
      return;
    }

    setState(() {
      isSubmittingToken = true;
      tokenError = null;
    });

    try {
      await ref.read(authProvider.notifier).loginWithToken(token);
    } catch (e) {
      setState(() {
        tokenError = "Couldn't log in with that token.";
      });
    } finally {
      if (mounted) {
        setState(() => isSubmittingToken = false);
      }
    }
  }

  @override
  void initState() {
    webviewController
        .loadRequest(Uri.parse("https://discord.com/login"))
        .then((_) async {
      await webviewController.clearCache();
      await webviewController.clearLocalStorage();

      setState(() {
        webviewInitialized = true;
      });

      webviewController
          .runJavaScript("document.body.style.backgroundColor = '#14161A';");

      webviewController
          .setNavigationDelegate(NavigationDelegate(onUrlChange: (change) {
        print("URL: ${change.url}");
        if (change.url?.contains("@me") ?? false) {
          webviewController
              .runJavaScriptReturningResult(
                  "(webpackChunkdiscord_app.push([[''],{},e=>{m=[];for(let c in e.c)m.push(e.c[c])}]),m).find(m=>m?.exports?.default?.getToken!==void 0).exports.default.getToken();")
              .then((value) async {
            // this sucks

            await ref
                .read(authProvider.notifier)
                .loginWithToken((value as String).replaceAll('"', ""));

            await webviewController.loadRequest(Uri.parse("about:blank"));
          });
        }
      }));
    });

    super.initState();
  }

  Widget _buildTokenForm(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: tokenController,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          style: GoogleFonts.publicSans(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Paste your Discord token",
            hintStyle: GoogleFonts.publicSans(
              color: const Color(0xFF808080),
            ),
            filled: true,
            fillColor: const Color(0xFF14161A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onSubmitted: (_) => isSubmittingToken ? null : _submitToken(),
        ),
        if (tokenError != null) ...[
          const SizedBox(height: 12),
          Text(
            tokenError!,
            style: GoogleFonts.publicSans(
              color: const Color(0xFFF04747),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: isSubmittingToken ? null : _submitToken,
          child: isSubmittingToken
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Log in"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 40),
            Text(
              "Welcome Back!",
              style: Theme.of(context).textTheme.titleLarge!,
            ),
            Text(
              "Let's get ya signed in",
              style: GoogleFonts.publicSans(
                color: const Color(0xFFC8C8C8),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: SizedBox(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: showTokenLogin
                      ? _buildTokenForm(context)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: webviewInitialized
                              ? WebViewWidget(
                                  controller: webviewController,
                                )
                              : const SizedBox(),
                        ),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  showTokenLogin = !showTokenLogin;
                  tokenError = null;
                });
              },
              child: Text(
                showTokenLogin ? "Log in with browser instead" : "Log in with token",
                style: GoogleFonts.publicSans(
                  color: const Color(0xFFC8C8C8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                bottom: bottomPadding + 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}