package dk.bryanmackayne.the12daydancer.android

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlin.math.abs
import kotlin.random.Random

@Composable
fun AudioAlbumScreen(
    resources: ResourceStore,
    album: AlbumDefinition,
    onBack: () -> Unit,
) {
    val context = LocalContext.current
    val player = remember(album.slug) { ExoPlayer.Builder(context).build() }

    var currentIndex by rememberSaveable(album.slug) { mutableIntStateOf(0) }
    var isPlaying by remember { mutableStateOf(false) }
    var position by remember { mutableLongStateOf(0L) }
    var duration by remember { mutableLongStateOf(1L) }
    var volume by remember { mutableFloatStateOf(0.86f) }
    var shuffle by remember { mutableStateOf(false) }
    var repeatOne by remember { mutableStateOf(false) }
    var status by remember { mutableStateOf("ready") }
    var query by rememberSaveable { mutableStateOf("") }
    var artworkIndex by remember { mutableStateOf<Int?>(null) }

    fun loadTrack(index: Int, autoplay: Boolean) {
        if (index !in album.tracks.indices) return
        val track = album.tracks[index]
        val uri = resources.uriFor(track.mediaResource)
        currentIndex = index
        if (uri == null) {
            status = "missing local media"
            player.stop()
            isPlaying = false
            return
        }
        player.setMediaItem(MediaItem.fromUri(uri))
        player.prepare()
        player.volume = volume
        player.repeatMode = if (repeatOne) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
        if (autoplay) player.play()
        status = if (autoplay) "playing" else "ready"
    }

    fun nextTrack(autoplay: Boolean = true) {
        if (album.tracks.isEmpty()) return
        val next = if (shuffle && album.tracks.size > 1) {
            var n = Random.nextInt(album.tracks.size)
            while (n == currentIndex) n = Random.nextInt(album.tracks.size)
            n
        } else {
            (currentIndex + 1) % album.tracks.size
        }
        loadTrack(next, autoplay)
    }

    fun previousTrack() {
        if (player.currentPosition > 3_000L) {
            player.seekTo(0)
        } else if (album.tracks.isNotEmpty()) {
            loadTrack((currentIndex - 1 + album.tracks.size) % album.tracks.size, true)
        }
    }

    LaunchedEffect(album.slug, resources.revision) {
        if (album.tracks.isNotEmpty() && resources.uriFor(album.tracks[currentIndex].mediaResource) != null) {
            loadTrack(currentIndex, false)
        }
    }

    LaunchedEffect(player, repeatOne) {
        player.repeatMode = if (repeatOne) Player.REPEAT_MODE_ONE else Player.REPEAT_MODE_OFF
    }

    LaunchedEffect(player) {
        while (isActive) {
            isPlaying = player.isPlaying
            position = player.currentPosition.coerceAtLeast(0L)
            val d = player.duration
            duration = if (d > 0L) d else 1L
            if (player.playbackState == Player.STATE_ENDED && !repeatOne) {
                nextTrack(true)
            }
            delay(250)
        }
    }

    DisposableEffect(player) {
        onDispose { player.release() }
    }

    val filtered = remember(query, album.tracks) {
        val q = query.trim()
        album.tracks.withIndex().filter { q.isEmpty() || it.value.title.contains(q, ignoreCase = true) }
    }

    Box(
        Modifier
            .fillMaxSize()
            .background(
                Brush.radialGradient(
                    listOf(Color(0xFF171F2B), Color.Black),
                    radius = 1100f,
                )
            )
    ) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(bottom = 54.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            item {
                AlbumTopBar(album.title, onBack)
                Box(Modifier.widthIn(max = 430.dp).fillMaxWidth().padding(horizontal = 10.dp)) {
                    AlbumHero(resources, album)
                }
                Spacer(Modifier.height(16.dp))
            }

            if (album.tracks.isNotEmpty()) {
                item {
                    NowPlayingPanel(
                        resources = resources,
                        album = album,
                        index = currentIndex,
                        isPlaying = isPlaying,
                        position = position,
                        duration = duration,
                        volume = volume,
                        shuffle = shuffle,
                        repeatOne = repeatOne,
                        status = status,
                        onArtwork = { artworkIndex = currentIndex },
                        onSeek = { player.seekTo(it) },
                        onVolume = {
                            volume = it
                            player.volume = it
                        },
                        onShuffle = { shuffle = !shuffle },
                        onRepeat = { repeatOne = !repeatOne },
                        onPrevious = ::previousTrack,
                        onNext = { nextTrack(true) },
                        onPlayPause = {
                            if (player.currentMediaItem == null) {
                                loadTrack(currentIndex, true)
                            } else if (player.isPlaying) {
                                player.pause()
                                status = "paused"
                            } else {
                                player.play()
                                status = "playing"
                            }
                        },
                    )
                    Spacer(Modifier.height(16.dp))
                }

                item {
                    Column(
                        modifier = Modifier
                            .widthIn(max = 430.dp)
                            .fillMaxWidth()
                            .padding(horizontal = 10.dp)
                            .clip(RoundedCornerShape(22.dp))
                            .background(Color.Black.copy(alpha = 0.44f)),
                    ) {
                        Column(
                            Modifier.padding(16.dp),
                            verticalArrangement = Arrangement.spacedBy(12.dp),
                        ) {
                            Text(
                                "${album.title} · ${album.tracks.size} tracks",
                                color = DancerCream,
                                fontFamily = FontFamily.Serif,
                                fontSize = 20.sp,
                            )
                            Text("Local native library", color = Color.White.copy(alpha = 0.55f), fontSize = 11.sp)
                            OutlinedTextField(
                                value = query,
                                onValueChange = { query = it },
                                modifier = Modifier.fillMaxWidth(),
                                placeholder = { Text("Search the album…") },
                                singleLine = true,
                                colors = OutlinedTextFieldDefaults.colors(
                                    focusedBorderColor = DancerGold,
                                    unfocusedBorderColor = Color.White.copy(alpha = 0.12f),
                                    focusedTextColor = DancerCream,
                                    unfocusedTextColor = DancerCream,
                                ),
                            )
                        }
                    }
                    Spacer(Modifier.height(4.dp))
                }

                itemsIndexed(filtered, key = { _, item -> item.value.mediaResource }) { _, indexed ->
                    TrackRow(
                        resources = resources,
                        track = indexed.value,
                        index = indexed.index,
                        isCurrent = indexed.index == currentIndex,
                        isPlaying = isPlaying,
                        onSelect = { loadTrack(indexed.index, true) },
                        onArtwork = { artworkIndex = indexed.index },
                    )
                }
            }
        }
    }

    artworkIndex?.let { initial ->
        ArtworkViewer(
            resources = resources,
            album = album,
            initialIndex = initial,
            onDismiss = { artworkIndex = null },
        )
    }
}

@Composable
private fun AlbumTopBar(title: String, onBack: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color.Black.copy(alpha = 0.92f))
            .statusBarsPadding()
            .height(54.dp)
            .padding(horizontal = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            "‹",
            color = DancerCream,
            fontSize = 38.sp,
            modifier = Modifier.clickable(onClick = onBack).padding(horizontal = 8.dp),
        )
        Text(
            title,
            color = DancerCream,
            fontFamily = FontFamily.Serif,
            fontSize = 16.sp,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.weight(1f),
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.width(44.dp))
    }
}

@Composable
private fun NowPlayingPanel(
    resources: ResourceStore,
    album: AlbumDefinition,
    index: Int,
    isPlaying: Boolean,
    position: Long,
    duration: Long,
    volume: Float,
    shuffle: Boolean,
    repeatOne: Boolean,
    status: String,
    onArtwork: () -> Unit,
    onSeek: (Long) -> Unit,
    onVolume: (Float) -> Unit,
    onShuffle: () -> Unit,
    onRepeat: () -> Unit,
    onPrevious: () -> Unit,
    onNext: () -> Unit,
    onPlayPause: () -> Unit,
) {
    val track = album.tracks[index]
    Column(
        modifier = Modifier
            .widthIn(max = 430.dp)
            .fillMaxWidth()
            .padding(horizontal = 10.dp)
            .clip(RoundedCornerShape(22.dp))
            .background(Brush.verticalGradient(listOf(Color.White.copy(alpha = 0.075f), Color.Black.copy(alpha = 0.28f))))
            .padding(18.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        ResourceImage(
            resources,
            track.artworkResource,
            Modifier
                .size(278.dp)
                .clip(RoundedCornerShape(14.dp))
                .clickable(onClick = onArtwork),
            ContentScale.Crop,
        )
        Text("NOW PLAYING", color = DancerGold, fontSize = 10.sp, fontWeight = FontWeight.Bold, letterSpacing = 2.2.sp)
        Text(
            track.title,
            color = DancerCream,
            fontFamily = FontFamily.Serif,
            fontSize = 24.sp,
            fontWeight = FontWeight.SemiBold,
            textAlign = TextAlign.Center,
            maxLines = 2,
        )
        Text(status, color = Color.White.copy(alpha = 0.55f), fontSize = 11.sp)

        Slider(
            value = position.coerceAtMost(duration).toFloat(),
            onValueChange = { onSeek(it.toLong()) },
            valueRange = 0f..duration.coerceAtLeast(1L).toFloat(),
            colors = SliderDefaults.colors(thumbColor = DancerGold, activeTrackColor = DancerGold),
        )
        Row(Modifier.fillMaxWidth()) {
            Text(formatTime(position), color = Color.White.copy(alpha = 0.55f), fontSize = 11.sp)
            Spacer(Modifier.weight(1f))
            Text(formatTime(duration), color = Color.White.copy(alpha = 0.55f), fontSize = 11.sp)
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            PlayerGlyph("⇄", active = shuffle, onClick = onShuffle)
            PlayerGlyph("|◀", onClick = onPrevious)
            PlayerGlyph(if (isPlaying) "❚❚" else "▶", large = true, onClick = onPlayPause)
            PlayerGlyph("▶|", onClick = onNext)
            PlayerGlyph("↻¹", active = repeatOne, onClick = onRepeat)
        }

        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("▮", color = Color.White.copy(alpha = 0.55f), fontSize = 11.sp)
            Slider(
                value = volume,
                onValueChange = onVolume,
                valueRange = 0f..1f,
                modifier = Modifier.weight(1f),
                colors = SliderDefaults.colors(thumbColor = DancerGold, activeTrackColor = DancerGold),
            )
            Text(")))", color = Color.White.copy(alpha = 0.55f), fontSize = 11.sp)
        }
    }
}

@Composable
private fun PlayerGlyph(
    glyph: String,
    active: Boolean = false,
    large: Boolean = false,
    onClick: () -> Unit,
) {
    Box(
        modifier = Modifier
            .size(if (large) 68.dp else 48.dp)
            .clip(RoundedCornerShape(50))
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            glyph,
            color = if (active) DancerGold else DancerCream,
            fontSize = if (large) 30.sp else 18.sp,
            fontWeight = FontWeight.Bold,
        )
    }
}

@Composable
private fun TrackRow(
    resources: ResourceStore,
    track: TrackDefinition,
    index: Int,
    isCurrent: Boolean,
    isPlaying: Boolean,
    onSelect: () -> Unit,
    onArtwork: () -> Unit,
) {
    Row(
        modifier = Modifier
            .widthIn(max = 430.dp)
            .fillMaxWidth()
            .padding(horizontal = 10.dp)
            .background(if (isCurrent) Color.White.copy(alpha = 0.06f) else Color.Transparent)
            .padding(horizontal = 13.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(11.dp),
    ) {
        Text(
            "%02d".format(index + 1),
            color = if (isCurrent) DancerGold else Color.White.copy(alpha = 0.45f),
            fontSize = 11.sp,
            modifier = Modifier.width(28.dp),
        )
        Column(
            modifier = Modifier.weight(1f).clickable(onClick = onSelect).padding(vertical = 10.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            Text(
                track.title,
                color = DancerCream,
                fontFamily = FontFamily.Serif,
                fontSize = 16.sp,
                fontWeight = FontWeight.SemiBold,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("Bryan MacKayne", color = Color.White.copy(alpha = 0.45f), fontSize = 10.sp)
                if (isCurrent) {
                    Text(if (isPlaying) "   )))" else "   ♪", color = DancerGold, fontSize = 11.sp)
                }
            }
        }
        ResourceImage(
            resources,
            track.artworkResource,
            Modifier
                .size(66.dp)
                .clip(RoundedCornerShape(9.dp))
                .clickable(onClick = onArtwork),
            ContentScale.Crop,
        )
    }
}

@Composable
private fun ArtworkViewer(
    resources: ResourceStore,
    album: AlbumDefinition,
    initialIndex: Int,
    onDismiss: () -> Unit,
) {
    var index by remember { mutableIntStateOf(initialIndex) }
    var dragX by remember { mutableFloatStateOf(0f) }
    var dragY by remember { mutableFloatStateOf(0f) }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false),
    ) {
        Box(
            Modifier
                .fillMaxSize()
                .background(Color.Black)
                .pointerInput(index) {
                    detectDragGestures(
                        onDragStart = { dragX = 0f; dragY = 0f },
                        onDrag = { _, amount -> dragX += amount.x; dragY += amount.y },
                        onDragEnd = {
                            if (abs(dragX) > abs(dragY) && abs(dragX) > 70f) {
                                index = if (dragX < 0) (index + 1) % album.tracks.size
                                else (index - 1 + album.tracks.size) % album.tracks.size
                            } else if (dragY > 90f) {
                                onDismiss()
                            }
                        },
                    )
                },
        ) {
            ResourceImage(
                resources,
                album.tracks[index].artworkResource,
                Modifier.fillMaxSize().padding(horizontal = 18.dp, vertical = 80.dp),
                ContentScale.Fit,
            )
            Text(
                "✕",
                color = Color.White,
                fontSize = 30.sp,
                modifier = Modifier.align(Alignment.TopEnd).statusBarsPadding().padding(16.dp).clickable(onClick = onDismiss),
            )
            Row(
                Modifier.align(Alignment.BottomCenter).navigationBarsPadding().fillMaxWidth().padding(14.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    "‹",
                    color = Color.White,
                    fontSize = 38.sp,
                    modifier = Modifier.clickable { index = (index - 1 + album.tracks.size) % album.tracks.size }.padding(12.dp),
                )
                Text(
                    album.tracks[index].title,
                    color = DancerCream,
                    fontWeight = FontWeight.SemiBold,
                    textAlign = TextAlign.Center,
                    maxLines = 2,
                    modifier = Modifier.weight(1f),
                )
                Text(
                    "›",
                    color = Color.White,
                    fontSize = 38.sp,
                    modifier = Modifier.clickable { index = (index + 1) % album.tracks.size }.padding(12.dp),
                )
            }
        }
    }
}

private fun formatTime(milliseconds: Long): String {
    val totalSeconds = (milliseconds.coerceAtLeast(0L) / 1000L).toInt()
    return "${totalSeconds / 60}:${(totalSeconds % 60).toString().padStart(2, '0')}"
}
