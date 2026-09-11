package dk.bryanmackayne.the12daydancer.android

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView

@Composable
fun VideoAlbumScreen(
    resources: ResourceStore,
    album: AlbumDefinition,
    onBack: () -> Unit,
) {
    val context = LocalContext.current
    val player = remember(album.slug) { ExoPlayer.Builder(context).build() }
    var currentIndex by rememberSaveable(album.slug) { mutableIntStateOf(0) }
    var fullScreen by remember { mutableStateOf(false) }
    var status by remember { mutableStateOf("ready") }

    fun play(index: Int, autoplay: Boolean = true) {
        if (index !in album.films.indices) return
        currentIndex = index
        val film = album.films[index]
        val uri = resources.uriFor(film.mediaResource)
        if (uri == null) {
            status = "missing local media"
            player.stop()
            return
        }
        player.setMediaItem(MediaItem.fromUri(uri))
        player.prepare()
        if (autoplay) player.play()
        status = if (autoplay) "playing" else "ready"
    }

    fun previous() {
        if (album.films.isNotEmpty()) {
            play((currentIndex - 1 + album.films.size) % album.films.size)
        }
    }

    fun next() {
        if (album.films.isNotEmpty()) {
            play((currentIndex + 1) % album.films.size)
        }
    }

    LaunchedEffect(album.slug, resources.revision) {
        if (album.films.isNotEmpty()) play(currentIndex, autoplay = false)
    }

    DisposableEffect(player) {
        onDispose { player.release() }
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
                AkitaTopBar(album.title, onBack)
                Box(Modifier.widthIn(max = 430.dp).fillMaxWidth().padding(horizontal = 10.dp)) {
                    AlbumHero(resources, album)
                }
                Spacer(Modifier.height(16.dp))
            }

            if (album.films.isNotEmpty()) {
                item {
                    Column(
                        modifier = Modifier
                            .widthIn(max = 430.dp)
                            .fillMaxWidth()
                            .padding(horizontal = 10.dp)
                            .clip(RoundedCornerShape(22.dp))
                            .background(Color.White.copy(alpha = 0.055f))
                            .padding(14.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(14.dp),
                    ) {
                        Box(
                            Modifier
                                .fillMaxWidth()
                                .aspectRatio(16f / 9f)
                                .clip(RoundedCornerShape(14.dp))
                                .background(Color.Black)
                        ) {
                            AndroidView(
                                factory = { ctx ->
                                    PlayerView(ctx).apply {
                                        useController = true
                                        this.player = player
                                    }
                                },
                                update = { it.player = player },
                                modifier = Modifier.fillMaxSize(),
                            )
                            Text(
                                "⛶",
                                color = Color.White,
                                fontSize = 22.sp,
                                modifier = Modifier
                                    .align(Alignment.TopEnd)
                                    .padding(8.dp)
                                    .clip(RoundedCornerShape(9.dp))
                                    .background(Color.Black.copy(alpha = 0.72f))
                                    .clickable { fullScreen = true }
                                    .padding(horizontal = 13.dp, vertical = 8.dp),
                            )
                        }

                        val film = album.films[currentIndex]
                        Text(
                            "NOW SHOWING",
                            color = DancerGold,
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold,
                            letterSpacing = 2.sp,
                        )
                        Text(
                            film.title,
                            color = DancerCream,
                            fontFamily = FontFamily.Serif,
                            fontSize = 21.sp,
                            fontWeight = FontWeight.SemiBold,
                            textAlign = TextAlign.Center,
                            maxLines = 2,
                        )
                        Text(
                            "Film ${currentIndex + 1} of ${album.films.size} · ${film.durationLabel} · $status",
                            color = Color.White.copy(alpha = 0.55f),
                            fontSize = 11.sp,
                        )
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(10.dp),
                        ) {
                            AkitaButton("|◀\nPrevious", ::previous, Modifier.weight(1f))
                            AkitaButton(
                                "↶\nReplay",
                                {
                                    player.seekTo(0)
                                    player.play()
                                    status = "playing"
                                },
                                Modifier.weight(1f),
                            )
                            AkitaButton("▶|\nNext", ::next, Modifier.weight(1f))
                        }
                    }
                    Spacer(Modifier.height(16.dp))
                }

                item {
                    Column(
                        modifier = Modifier
                            .widthIn(max = 430.dp)
                            .fillMaxWidth()
                            .padding(horizontal = 10.dp)
                            .clip(RoundedCornerShape(20.dp))
                            .background(Color.Black.copy(alpha = 0.42f))
                            .padding(14.dp),
                        verticalArrangement = Arrangement.spacedBy(5.dp),
                    ) {
                        Text(
                            "${album.title} · ${album.films.size} films",
                            color = DancerCream,
                            fontFamily = FontFamily.Serif,
                            fontSize = 20.sp,
                        )
                        Text(
                            "Nine Tales from the Gaman Canon",
                            color = Color.White.copy(alpha = 0.52f),
                            fontSize = 11.sp,
                        )
                    }
                    Spacer(Modifier.height(5.dp))
                }

                itemsIndexed(album.films, key = { _, film -> film.mediaResource }) { index, film ->
                    Row(
                        modifier = Modifier
                            .widthIn(max = 430.dp)
                            .fillMaxWidth()
                            .padding(horizontal = 10.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .background(if (index == currentIndex) Color.White.copy(alpha = 0.07f) else Color.Transparent)
                            .clickable { play(index) }
                            .padding(horizontal = 13.dp, vertical = 13.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                            "%02d".format(index + 1),
                            color = if (index == currentIndex) DancerGold else Color.White.copy(alpha = 0.42f),
                            fontSize = 11.sp,
                            modifier = Modifier.width(32.dp),
                        )
                        Column(Modifier.weight(1f)) {
                            Text(
                                film.title,
                                color = DancerCream,
                                fontFamily = FontFamily.Serif,
                                fontSize = 16.sp,
                                fontWeight = FontWeight.SemiBold,
                                maxLines = 2,
                                overflow = TextOverflow.Ellipsis,
                            )
                            Text(
                                film.durationLabel,
                                color = Color.White.copy(alpha = 0.45f),
                                fontSize = 10.sp,
                            )
                        }
                        Text(
                            if (index == currentIndex) "▶" else "▣",
                            color = if (index == currentIndex) DancerGold else Color.White.copy(alpha = 0.58f),
                            fontSize = 18.sp,
                        )
                    }
                }
            }
        }
    }

    if (fullScreen) {
        Dialog(
            onDismissRequest = { fullScreen = false },
            properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false),
        ) {
            Box(Modifier.fillMaxSize().background(Color.Black)) {
                AndroidView(
                    factory = { ctx ->
                        PlayerView(ctx).apply {
                            useController = true
                            this.player = player
                        }
                    },
                    update = { it.player = player },
                    modifier = Modifier.fillMaxSize(),
                )
                Text(
                    "✕",
                    color = Color.White,
                    fontSize = 30.sp,
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .statusBarsPadding()
                        .padding(16.dp)
                        .clickable { fullScreen = false },
                )
            }
        }
    }
}

@Composable
private fun AkitaTopBar(title: String, onBack: () -> Unit) {
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
            textAlign = TextAlign.Center,
            modifier = Modifier.weight(1f),
        )
        Spacer(Modifier.width(44.dp))
    }
}

@Composable
private fun AkitaButton(label: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Button(
        onClick = onClick,
        modifier = modifier.height(58.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = Color.White.copy(alpha = 0.10f),
            contentColor = DancerCream,
        ),
        contentPadding = PaddingValues(4.dp),
    ) {
        Text(label, textAlign = TextAlign.Center, fontSize = 11.sp, lineHeight = 14.sp)
    }
}
