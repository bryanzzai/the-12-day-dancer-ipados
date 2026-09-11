package dk.bryanzzai.the12daydancer.android

import android.media.MediaMetadataRetriever
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
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
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
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
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

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

    fun loadFilm(index: Int, autoplay: Boolean) {
        if (index !in album.films.indices) return
        currentIndex = index
        val uri = resources.uriFor(album.films[index].mediaResource)
        if (uri == null) {
            player.stop()
            status = "missing local media"
            return
        }
        player.setMediaItem(MediaItem.fromUri(uri))
        player.prepare()
        if (autoplay) player.play()
        status = if (autoplay) "playing" else "ready"
    }

    fun next() {
        if (album.films.isNotEmpty()) loadFilm((currentIndex + 1) % album.films.size, true)
    }

    fun previous() {
        if (album.films.isNotEmpty()) loadFilm((currentIndex - 1 + album.films.size) % album.films.size, true)
    }

    LaunchedEffect(album.slug, resources.revision) {
        if (album.films.isNotEmpty() && resources.uriFor(album.films[currentIndex].mediaResource) != null) {
            loadFilm(currentIndex, false)
        }
    }

    DisposableEffect(player) {
        onDispose { player.release() }
    }

    Box(Modifier.fillMaxSize().background(Color.Black)) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(bottom = 54.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            item {
                VideoTopBar(album.title, onBack)
                Box(Modifier.widthIn(max = 430.dp).fillMaxWidth().padding(horizontal = 10.dp)) {
                    AlbumHero(resources, album)
                }
                Spacer(Modifier.height(16.dp))
            }

            if (album.films.isNotEmpty()) {
                item {
                    CinemaPanel(
                        player = player,
                        film = album.films[currentIndex],
                        index = currentIndex,
                        filmCount = album.films.size,
                        status = status,
                        onFullScreen = { fullScreen = true },
                        onPrevious = ::previous,
                        onReplay = {
                            player.seekTo(0)
                            player.play()
                            status = "playing"
                        },
                        onNext = ::next,
                    )
                    Spacer(Modifier.height(16.dp))
                }

                item {
                    Column(
                        modifier = Modifier
                            .widthIn(max = 430.dp)
                            .fillMaxWidth()
                            .padding(horizontal = 10.dp)
                            .clip(RoundedCornerShape(20.dp))
                            .background(Color.Black.copy(alpha = 0.40f))
                            .padding(14.dp),
                        verticalArrangement = Arrangement.spacedBy(13.dp),
                    ) {
                        Text(
                            "${album.title} · ${album.films.size} films",
                            color = DancerCream,
                            fontFamily = FontFamily.Serif,
                            fontSize = 20.sp,
                        )
                        album.films.forEachIndexed { index, film ->
                            FilmCard(
                                resources = resources,
                                film = film,
                                index = index,
                                isCurrent = index == currentIndex,
                                onClick = { loadFilm(index, true) },
                            )
                        }
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
private fun VideoTopBar(title: String, onBack: () -> Unit) {
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
private fun CinemaPanel(
    player: ExoPlayer,
    film: FilmDefinition,
    index: Int,
    filmCount: Int,
    status: String,
    onFullScreen: () -> Unit,
    onPrevious: () -> Unit,
    onReplay: () -> Unit,
    onNext: () -> Unit,
) {
    Column(
        modifier = Modifier
            .widthIn(max = 430.dp)
            .fillMaxWidth()
            .padding(horizontal = 10.dp)
            .clip(RoundedCornerShape(20.dp))
            .background(Color.White.copy(alpha = 0.055f))
            .padding(14.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Box(Modifier.fillMaxWidth().aspectRatio(16f / 9f).clip(RoundedCornerShape(14.dp)).background(Color.Black)) {
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
                    .padding(9.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .background(Color.Black.copy(alpha = 0.78f))
                    .clickable(onClick = onFullScreen)
                    .padding(horizontal = 14.dp, vertical = 9.dp),
            )
        }
        Text("NOW SHOWING", color = DancerGold, fontSize = 10.sp, fontWeight = FontWeight.Bold, letterSpacing = 2.sp)
        Text(
            film.title,
            color = DancerCream,
            fontFamily = FontFamily.Serif,
            fontSize = 20.sp,
            fontWeight = FontWeight.SemiBold,
            textAlign = TextAlign.Center,
            maxLines = 2,
        )
        Text(
            "Film ${index + 1} of $filmCount · ${film.durationLabel}${if (status != "ready") " · $status" else ""}",
            color = Color.White.copy(alpha = 0.55f),
            fontSize = 11.sp,
        )
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            CinemaButton("|◀\nPrevious", onPrevious, Modifier.weight(1f))
            CinemaButton("↶\nReplay", onReplay, Modifier.weight(1f))
            CinemaButton("▶|\nNext", onNext, Modifier.weight(1f))
        }
    }
}

@Composable
private fun CinemaButton(label: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
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

@Composable
private fun FilmCard(
    resources: ResourceStore,
    film: FilmDefinition,
    index: Int,
    isCurrent: Boolean,
    onClick: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(Color.Black.copy(alpha = 0.50f))
            .clickable(onClick = onClick),
    ) {
        Box(Modifier.fillMaxWidth().height(205.dp)) {
            VideoThumbnail(resources, film, Modifier.fillMaxSize())
            Box(
                Modifier.fillMaxSize().background(
                    Brush.verticalGradient(listOf(Color.Transparent, Color.Transparent, Color.Black.copy(alpha = 0.65f)))
                )
            )
            Text(
                "%02d".format(index + 1),
                color = DancerGold,
                fontSize = 10.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier
                    .padding(10.dp)
                    .clip(RoundedCornerShape(5.dp))
                    .background(Color.Black.copy(alpha = 0.78f))
                    .padding(horizontal = 8.dp, vertical = 5.dp),
            )
            Text(
                if (isCurrent) "▶" else "▣",
                color = if (isCurrent) DancerGold else Color.White.copy(alpha = 0.84f),
                fontSize = 22.sp,
                modifier = Modifier.align(Alignment.TopEnd).padding(12.dp),
            )
        }
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                film.title,
                color = DancerCream,
                fontFamily = FontFamily.Serif,
                fontSize = 16.sp,
                fontWeight = FontWeight.SemiBold,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.weight(1f),
            )
            Text(film.durationLabel, color = Color.White.copy(alpha = 0.50f), fontSize = 11.sp)
        }
    }
}

@Composable
private fun VideoThumbnail(resources: ResourceStore, film: FilmDefinition, modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val revision = resources.revision
    var bitmap by remember(film.mediaResource, revision) { mutableStateOf<androidx.compose.ui.graphics.ImageBitmap?>(null) }

    LaunchedEffect(film.mediaResource, revision) {
        bitmap = withContext(Dispatchers.IO) {
            val uri = resources.uriFor(film.mediaResource) ?: return@withContext null
            runCatching {
                val retriever = MediaMetadataRetriever()
                try {
                    retriever.setDataSource(context, uri)
                    retriever.getFrameAtTime(1_000_000L, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)?.asImageBitmap()
                } finally {
                    retriever.release()
                }
            }.getOrNull()
        }
    }

    val image = bitmap
    if (image != null) {
        Image(image, null, modifier, contentScale = ContentScale.Crop)
    } else {
        Box(modifier.background(Color(0xFF151515)), contentAlignment = Alignment.Center) {
            Text("FILM", color = Color.White.copy(alpha = 0.35f), letterSpacing = 2.sp)
        }
    }
}
