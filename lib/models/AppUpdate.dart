// lib/models/app_update.dart
class AppUpdate {
  final int    id;
  final String platform;
  final String version;      // “2.5.1”
  final bool   mandatory;    // true ⇒ force-update
  final String releaseNotes;
  final String downloadUrl;

  const AppUpdate({
    required this.id,
    required this.platform,
    required this.version,
    required this.mandatory,
    required this.releaseNotes,
    required this.downloadUrl,
  });

  factory AppUpdate.fromJson(Map<String, dynamic> j) => AppUpdate(
        id:            j['id'],
        platform:      j['platform'],
        version:       j['version'],
        mandatory:     j['mandatory'],
        releaseNotes:  j['releaseNotes'] ?? '',
        downloadUrl:   j['downloadUrl'],
      );
}