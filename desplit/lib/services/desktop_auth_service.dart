import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

/// Handles Google and GitHub OAuth authentication for desktop platforms (Windows, macOS, Linux)
/// by coordinating a secure local loopback server with the browser and Firebase Auth.
class DesktopAuthService {
  static final DesktopAuthService instance = DesktopAuthService._internal();
  DesktopAuthService._internal();

  HttpServer? _activeServer;
  Completer<UserCredential>? _activeCompleter;

  void cancelActiveAuth() {
    try {
      _activeServer?.close(force: true);
    } catch (_) {}
    _activeServer = null;

    if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
      _activeCompleter!.completeError(
        FirebaseAuthException(
          code: 'popup-closed-by-user',
          message: 'Sign-in was cancelled.',
        ),
      );
    }
    _activeCompleter = null;
  }

  Future<UserCredential> signInWithGoogle() async {
    return _signInWithProvider('google');
  }

  Future<UserCredential> signInWithGitHub() async {
    return _signInWithProvider('github');
  }

  Future<UserCredential> _signInWithProvider(String providerName) async {
    cancelActiveAuth();

    final completer = Completer<UserCredential>();
    _activeCompleter = completer;

    HttpServer? server;
    try {
      // Bind to an arbitrary available port on localhost
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _activeServer = server;
      final port = server.port;

      final authUrl = 'http://localhost:$port/?provider=$providerName';

      // Listen for incoming requests from the browser
      server.listen(
        (HttpRequest request) async {
          // Set CORS headers
          request.response.headers.set('Access-Control-Allow-Origin', '*');
          request.response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
          request.response.headers.set('Access-Control-Allow-Headers', 'Content-Type');

          if (request.method == 'OPTIONS') {
            request.response.statusCode = HttpStatus.ok;
            await request.response.close();
            return;
          }

          final path = request.uri.path;

          if (request.method == 'GET' && (path == '/' || path.isEmpty)) {
            // Serve the OAuth landing page
            final html = _getAuthHtml(providerName);
            request.response.headers.contentType = ContentType.html;
            request.response.statusCode = HttpStatus.ok;
            request.response.write(html);
            await request.response.close();
          } else if (request.method == 'POST' && path == '/callback') {
            try {
              final content = await utf8.decodeStream(request);
              final data = jsonDecode(content) as Map<String, dynamic>;

              final p = data['provider'] as String? ?? providerName;
              final idToken = data['idToken'] as String?;
              final accessToken = data['accessToken'] as String?;

              AuthCredential? credential;
              if (p == 'google') {
                credential = GoogleAuthProvider.credential(
                  idToken: idToken,
                  accessToken: accessToken,
                );
              } else if (p == 'github') {
                if (accessToken != null && accessToken.isNotEmpty) {
                  credential = GithubAuthProvider.credential(accessToken);
                } else {
                  throw Exception('GitHub access token was missing.');
                }
              }

              if (credential == null) {
                throw Exception('Could not build credentials for provider: $p');
              }

              // Send 200 OK back to browser
              request.response.headers.contentType = ContentType.json;
              request.response.statusCode = HttpStatus.ok;
              request.response.write(jsonEncode({'status': 'ok'}));
              await request.response.close();

              // Sign into Firebase Auth on Windows with the credential
              final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

              if (!completer.isCompleted) {
                completer.complete(userCredential);
              }
            } catch (e) {
              request.response.headers.contentType = ContentType.json;
              request.response.statusCode = HttpStatus.internalServerError;
              request.response.write(jsonEncode({'error': e.toString()}));
              await request.response.close();

              if (!completer.isCompleted) {
                completer.completeError(e);
              }
            }
          } else if (request.method == 'POST' && path == '/error') {
            try {
              final content = await utf8.decodeStream(request);
              final data = jsonDecode(content) as Map<String, dynamic>;
              final errorMsg = data['error'] as String? ?? 'Authentication cancelled';

              request.response.headers.contentType = ContentType.json;
              request.response.statusCode = HttpStatus.ok;
              request.response.write(jsonEncode({'status': 'received'}));
              await request.response.close();

              if (!completer.isCompleted) {
                completer.completeError(
                  FirebaseAuthException(
                    code: 'popup-closed-by-user',
                    message: errorMsg,
                  ),
                );
              }
            } catch (_) {
              if (!completer.isCompleted) {
                completer.completeError(
                  FirebaseAuthException(
                    code: 'popup-closed-by-user',
                    message: 'Authentication was cancelled.',
                  ),
                );
              }
            }
          } else {
            request.response.statusCode = HttpStatus.notFound;
            await request.response.close();
          }
        },
        onError: (err) {
          if (!completer.isCompleted) {
            completer.completeError(err);
          }
        },
      );

      // Launch default system browser to the local server URL
      await _openBrowser(authUrl);

      // Wait for completion with timeout
      return await completer.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () {
          throw FirebaseAuthException(
            code: 'popup-closed-by-user',
            message: 'Authentication timed out. Please try again.',
          );
        },
      );
    } finally {
      try {
        await server?.close(force: true);
      } catch (_) {}
      if (_activeServer == server) {
        _activeServer = null;
      }
      if (_activeCompleter == completer) {
        _activeCompleter = null;
      }
    }
  }

  Future<void> _openBrowser(String url) async {
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', url]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (e) {
      debugPrint('Failed to open browser: $e');
    }
  }

  String _getAuthHtml(String provider) {
    final isGoogle = provider == 'google';
    final providerTitle = isGoogle ? 'Google' : 'GitHub';
    final apiKey = DefaultFirebaseOptions.web.apiKey;
    final authDomain = DefaultFirebaseOptions.web.authDomain;
    final projectId = DefaultFirebaseOptions.web.projectId;
    final appId = DefaultFirebaseOptions.web.appId;

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>deSplit - Sign In with $providerTitle</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <script src="https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/10.8.0/firebase-auth-compat.js"></script>
  <style>
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    }
    body {
      background-color: #0B0819;
      background-image: 
        radial-gradient(circle at 50% 0%, rgba(124, 58, 237, 0.15), transparent 45%),
        radial-gradient(circle at 100% 100%, rgba(168, 85, 247, 0.08), transparent 40%);
      color: #F8FAFC;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 20px;
    }
    .auth-card {
      background: rgba(20, 18, 41, 0.95);
      border: 1px solid rgba(124, 58, 237, 0.25);
      border-radius: 20px;
      padding: 40px 36px;
      width: 100%;
      max-width: 420px;
      text-align: center;
      box-shadow: 
        0 20px 40px -15px rgba(0, 0, 0, 0.6),
        0 0 50px -10px rgba(124, 58, 237, 0.18);
      position: relative;
      overflow: hidden;
    }
    .brand-header {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      margin-bottom: 24px;
    }
    .brand-title {
      font-size: 24px;
      font-weight: 700;
      letter-spacing: -0.5px;
    }
    .brand-title span {
      color: #A855F7;
    }
    .spinner {
      width: 48px;
      height: 48px;
      margin: 20px auto;
      border: 3px solid rgba(168, 85, 247, 0.15);
      border-top-color: #A855F7;
      border-radius: 50%;
      animation: spin 0.9s cubic-bezier(0.55, 0.15, 0.45, 0.85) infinite;
    }
    @keyframes spin {
      to { transform: rotate(360deg); }
    }
    .status-title {
      font-size: 19px;
      font-weight: 600;
      margin-bottom: 10px;
      color: #FFFFFF;
    }
    .status-desc {
      font-size: 13.5px;
      color: #94A3B8;
      line-height: 1.5;
      margin-bottom: 24px;
    }
    .action-btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      background: linear-gradient(135deg, #7C3AED, #A855F7);
      color: white;
      border: none;
      border-radius: 10px;
      padding: 12px 28px;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      box-shadow: 0 4px 15px rgba(124, 58, 237, 0.35);
      transition: all 0.2s ease;
      text-decoration: none;
      width: 100%;
    }
    .action-btn:hover {
      transform: translateY(-1px);
      box-shadow: 0 6px 20px rgba(124, 58, 237, 0.45);
    }
    .success-badge {
      width: 56px;
      height: 56px;
      background: rgba(16, 185, 129, 0.15);
      border: 1px solid rgba(16, 185, 129, 0.3);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 20px;
      color: #10B981;
      font-size: 26px;
      font-weight: bold;
    }
    .close-btn {
      background: rgba(255, 255, 255, 0.08);
      border: 1px solid rgba(255, 255, 255, 0.15);
      color: #E2E8F0;
      padding: 10px 20px;
      border-radius: 8px;
      font-size: 13px;
      cursor: pointer;
      margin-top: 16px;
    }
    .close-btn:hover {
      background: rgba(255, 255, 255, 0.12);
    }
  </style>
</head>
<body>
  <div class="auth-card" id="card">
    <div class="brand-header">
      <div class="brand-title">de<span>Split</span></div>
    </div>

    <div class="spinner" id="spinner"></div>

    <h2 class="status-title" id="status-title">Signing in with $providerTitle...</h2>
    <p class="status-desc" id="status-desc">
      A secure sign-in window should open automatically.<br>
      If your browser blocked the popup, click the button below.
    </p>

    <button class="action-btn" id="action-btn" onclick="triggerAuth()">
      Continue with $providerTitle
    </button>
  </div>

  <script>
    const firebaseConfig = {
      apiKey: "$apiKey",
      authDomain: "$authDomain",
      projectId: "$projectId",
      appId: "$appId"
    };

    if (!firebase.apps.length) {
      firebase.initializeApp(firebaseConfig);
    }

    const providerName = '$provider';

    function getProvider() {
      if (providerName === 'google') {
        const p = new firebase.auth.GoogleAuthProvider();
        p.addScope('email');
        p.addScope('profile');
        return p;
      } else {
        const p = new firebase.auth.GithubAuthProvider();
        p.addScope('read:user');
        p.addScope('user:email');
        return p;
      }
    }

    let authInProgress = false;

    function triggerAuth() {
      if (authInProgress) return;
      authInProgress = true;

      document.getElementById('status-title').innerText = 'Authenticating...';
      document.getElementById('status-desc').innerText = 'Please complete sign in within the opened popup window.';
      document.getElementById('action-btn').style.opacity = '0.6';
      document.getElementById('spinner').style.display = 'block';

      const provider = getProvider();

      firebase.auth().signInWithPopup(provider)
        .then(async function(result) {
          document.getElementById('status-title').innerText = 'Connecting to DeSplit...';
          document.getElementById('status-desc').innerText = 'Transferring credentials to the desktop app...';

          const credential = result.credential;
          const user = result.user;

          const payload = {
            provider: providerName,
            idToken: credential ? credential.idToken : null,
            accessToken: credential ? credential.accessToken : null,
            email: user.email,
            displayName: user.displayName,
            photoURL: user.photoURL,
            uid: user.uid
          };

          try {
            await fetch('/callback', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify(payload)
            });

            document.getElementById('card').innerHTML = `
              <div class="brand-header">
                <div class="brand-title">de<span>Split</span></div>
              </div>
              <div class="success-badge">✓</div>
              <h2 class="status-title" style="color:#10B981">Signed in successfully!</h2>
              <p class="status-desc">
                Welcome back, <b>\${user.displayName || user.email || 'User'}</b>.<br>
                You can now close this tab and return to the DeSplit app.
              </p>
              <button class="close-btn" onclick="window.close()">Close Tab</button>
            `;

            setTimeout(function() {
              window.close();
            }, 2000);
          } catch (postErr) {
            document.getElementById('status-title').innerText = 'Sync Error';
            document.getElementById('status-desc').innerText = 'Failed to pass credentials back to DeSplit app: ' + postErr;
          }
        })
        .catch(function(error) {
          authInProgress = false;
          document.getElementById('action-btn').style.opacity = '1';
          console.error(error);

          if (error.code === 'auth/popup-blocked') {
            document.getElementById('status-title').innerText = 'Popup Blocked';
            document.getElementById('status-desc').innerText = 'Your browser blocked the sign-in popup. Please click "Continue with $providerTitle" below to open it.';
          } else if (error.code === 'auth/popup-closed-by-user') {
            document.getElementById('status-title').innerText = 'Window Closed';
            document.getElementById('status-desc').innerText = 'The sign-in window was closed before finishing. Click below to try again.';
          } else {
            document.getElementById('status-title').innerText = 'Authentication Failed';
            document.getElementById('status-desc').innerText = error.message || error.code || 'An unknown error occurred.';
            
            fetch('/error', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ error: error.message || error.code })
            }).catch(function() {});
          }
        });
    }

    // Attempt automatic popup launch on page load
    window.addEventListener('load', function() {
      setTimeout(function() {
        triggerAuth();
      }, 400);
    });
  </script>
</body>
</html>
''';
  }
}
