// ignore_for_file: avoid_web_libraries_in_flutter, undefined_prefixed_name
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

void registerWebVideoFactory(String viewId, String videoUrl, bool autoplay, Function(bool ready, String? error) onStateChange) {
  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int id) {
      final video = html.VideoElement()
        ..src = videoUrl
        ..autoplay = autoplay
        ..muted = false
        ..loop = true
        ..controls = false
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.backgroundColor = '#000000';
      
      video.onLoadedData.listen((event) {
        print('✅ CLIPS WEB: Vídeo carregado com sucesso');
        print('  URL: $videoUrl');
        print('  Resolução: ${video.videoWidth}x${video.videoHeight}');
        print('  Duração: ${video.duration.toInt()}s');
        onStateChange(true, null);
      });
      
      video.onError.listen((event) {
        print('❌ CLIPS WEB: Erro ao carregar vídeo');
        print('  URL: $videoUrl');
        onStateChange(false, 'Falha ao reproduzir vídeo no navegador.\n\n⚠️ Verifique se o formato é suportado (MP4/H.264).');
      });
      
      return video;
    },
  );
}
