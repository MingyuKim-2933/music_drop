package kr.soundmate.soundmate

import android.content.ComponentName
import android.content.Context
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * 기기 내 음악 앱(멜론, 지니, FLO, 유튜브뮤직, 스포티파이 등)의
 * MediaSession을 구독해서 "지금 재생 중" 정보를 Flutter로 흘려보낸다.
 */
class MediaSessionTracker(
    private val context: Context,
    private val events: EventChannel.EventSink,
) {
    // 감지 대상 음악 앱 패키지 (그 외 앱의 미디어 세션은 무시)
    private val musicPackages = setOf(
        "com.iloen.melon",                      // 멜론
        "com.ktmusic.geniemusic",               // 지니뮤직
        "skplanet.musicmate",                   // FLO
        "com.google.android.apps.youtube.music",// 유튜브 뮤직
        "com.spotify.music",                    // 스포티파이
        "com.naver.vibe",                       // VIBE
        "com.neowiz.android.bugs",              // 벅스
    )

    private val mainHandler = Handler(Looper.getMainLooper())
    private val manager =
        context.getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
    private val listenerComponent =
        ComponentName(context, MediaNotificationListener::class.java)

    private val callbacks = mutableMapOf<MediaController, MediaController.Callback>()

    private val sessionsListener =
        MediaSessionManager.OnActiveSessionsChangedListener { controllers ->
            attach(controllers ?: emptyList())
        }

    fun start() {
        manager.addOnActiveSessionsChangedListener(sessionsListener, listenerComponent)
        attach(manager.getActiveSessions(listenerComponent))
    }

    fun stop() {
        manager.removeOnActiveSessionsChangedListener(sessionsListener)
        callbacks.forEach { (controller, cb) -> controller.unregisterCallback(cb) }
        callbacks.clear()
    }

    private fun attach(controllers: List<MediaController>) {
        callbacks.forEach { (controller, cb) -> controller.unregisterCallback(cb) }
        callbacks.clear()

        controllers
            .filter { it.packageName in musicPackages }
            .forEach { controller ->
                val cb = object : MediaController.Callback() {
                    override fun onMetadataChanged(metadata: MediaMetadata?) {
                        emit(controller)
                    }

                    override fun onPlaybackStateChanged(state: PlaybackState?) {
                        emit(controller)
                    }
                }
                controller.registerCallback(cb, mainHandler)
                callbacks[controller] = cb
            }

        // 현재 재생 중인 세션을 즉시 한 번 전송
        controllers
            .filter { it.packageName in musicPackages }
            .maxByOrNull { if (it.playbackState?.state == PlaybackState.STATE_PLAYING) 1 else 0 }
            ?.let { emit(it) }
    }

    private fun emit(controller: MediaController) {
        val metadata = controller.metadata ?: return
        val title = metadata.getString(MediaMetadata.METADATA_KEY_TITLE) ?: return
        val artist = metadata.getString(MediaMetadata.METADATA_KEY_ARTIST)
            ?: metadata.getString(MediaMetadata.METADATA_KEY_ALBUM_ARTIST)
            ?: ""
        val isPlaying =
            controller.playbackState?.state == PlaybackState.STATE_PLAYING

        mainHandler.post {
            events.success(
                mapOf(
                    "title" to title,
                    "artist" to artist,
                    "package" to controller.packageName,
                    "isPlaying" to isPlaying,
                )
            )
        }
    }
}
