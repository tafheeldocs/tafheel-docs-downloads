import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DownloadPage extends StatelessWidget {
  const DownloadPage({super.key});

  static const String webAppUrl =
      'https://tafheel-creation.web.app';

  static const String androidUrl =
      'https://github.com/tafheeldocs/tafheel-docs-downloads/releases/download/v1.0.0/app-release.zip';

  static const String windowsUrl =
      'https://github.com/tafheeldocs/tafheel-docs-downloads/releases/download/v1.0.0/TAFHEEL-DOCS-Windows-v1.0.0.zip';

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 600,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8F500),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.description_rounded,
                    size: 52,
                    color: Color(0xFF0D1B2A),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'TAFHEEL DOCS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC8F500),
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Company & Employee\nDocument Expiry Tracker',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.4,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 40),

                const Text(
                  'Choose your platform',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                // WEB APP
                _DownloadButton(
                  icon: Icons.language,
                  title: 'Open Web App',
                  subtitle: 'Use TAFHEEL DOCS in your browser',
                  onTap: () => _openUrl(webAppUrl),
                ),

                const SizedBox(height: 14),

                // ANDROID
                _DownloadButton(
                  icon: Icons.android,
                  title: 'Download Android App',
                  subtitle: 'Android APK • v1.0.0',
                  onTap: () => _openUrl(androidUrl),
                ),

                const SizedBox(height: 14),

                // WINDOWS
                _DownloadButton(
                  icon: Icons.desktop_windows,
                  title: 'Download Windows App',
                  subtitle: 'Windows • v1.0.0',
                  onTap: () => _openUrl(windowsUrl),
                ),

                const SizedBox(height: 36),

                const Text(
                  'TAFHEEL DOCS',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  '© 2026 All Rights Reserved',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DownloadButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: const Color(0xFF1B2A38),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8F500),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF0D1B2A),
                    size: 30,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFC8F500),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}