void registerWebVideoFactory(String viewId, String videoUrl, bool autoplay, Function(bool ready, String? error) onStateChange) {
  throw UnsupportedError('Web video is not supported on this platform');
}
