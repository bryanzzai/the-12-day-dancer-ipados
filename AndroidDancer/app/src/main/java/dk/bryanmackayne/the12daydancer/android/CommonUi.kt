package dk.bryanmackayne.the12daydancer.android

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

val DancerGold = Color(0xFFD4AD54)
val DancerCream = Color(0xFFF5E8C7)
val DancerMutedGold = Color(0xFFC9B085)
val DancerPanel = Color(0xFF0E0F0F)

@Composable
fun DancerTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = darkColorScheme(
            primary = DancerGold,
            onPrimary = Color.Black,
            background = Color.Black,
            surface = DancerPanel,
            onBackground = DancerCream,
            onSurface = DancerCream,
        ),
        typography = MaterialTheme.typography.copy(
            bodyLarge = MaterialTheme.typography.bodyLarge.copy(fontFamily = FontFamily.Serif),
            bodyMedium = MaterialTheme.typography.bodyMedium.copy(fontFamily = FontFamily.Serif),
            titleLarge = MaterialTheme.typography.titleLarge.copy(fontFamily = FontFamily.Serif),
        ),
        content = content,
    )
}

@Composable
fun ResourceImage(
    resources: ResourceStore,
    resource: String,
    modifier: Modifier = Modifier,
    contentScale: ContentScale = ContentScale.Crop,
) {
    val revision = resources.revision
    var image by remember(resource, revision) { mutableStateOf<androidx.compose.ui.graphics.ImageBitmap?>(null) }

    LaunchedEffect(resource, revision) {
        image = withContext(Dispatchers.IO) { resources.image(resource) }
    }

    val bitmap = image
    if (bitmap != null) {
        Image(
            bitmap = bitmap,
            contentDescription = null,
            modifier = modifier,
            contentScale = contentScale,
        )
    } else {
        Box(
            modifier = modifier.background(
                Brush.linearGradient(
                    listOf(Color(0xFF242424), Color(0xFF080808)),
                    start = Offset.Zero,
                    end = Offset.Infinite,
                )
            ),
            contentAlignment = Alignment.Center,
        ) {
            Text("◇", color = Color.White.copy(alpha = 0.35f), fontSize = 32.sp)
        }
    }
}

@Composable
fun AlbumHero(resources: ResourceStore, album: AlbumDefinition) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(220.dp)
            .clip(RoundedCornerShape(0.dp)),
    ) {
        ResourceImage(
            resources = resources,
            resource = album.bannerResource,
            modifier = Modifier.fillMaxSize(),
        )
        Box(
            Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        listOf(Color.Black.copy(alpha = 0.18f), Color.Black.copy(alpha = 0.20f), Color.Black.copy(alpha = 0.92f))
                    )
                )
        )
        ResourceImage(
            resources = resources,
            resource = album.portraitResource,
            modifier = Modifier
                .width(126.dp)
                .fillMaxHeight()
                .drawWithContent {
                    drawContent()
                    drawRect(
                        brush = Brush.horizontalGradient(
                            0f to Color.Transparent,
                            0.66f to Color.Transparent,
                            1f to Color.Black,
                        ),
                        blendMode = androidx.compose.ui.graphics.BlendMode.DstIn,
                    )
                },
        )
        Column(
            modifier = Modifier
                .align(Alignment.BottomStart)
                .padding(start = 112.dp, end = 14.dp, bottom = 14.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            Text(
                "BRYAN MACKAYNE",
                color = DancerGold,
                fontSize = 9.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 2.2.sp,
            )
            Text(
                album.title,
                color = DancerCream,
                fontFamily = FontFamily.Serif,
                fontSize = 32.sp,
                fontWeight = FontWeight.Medium,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Text(
                album.subtitle,
                color = Color.White.copy(alpha = 0.86f),
                fontFamily = FontFamily.Serif,
                fontSize = 16.sp,
                maxLines = 2,
            )
            Text(
                album.description,
                color = Color.White.copy(alpha = 0.72f),
                fontSize = 12.sp,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}

@Composable
fun DancerMast() {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(9.dp),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Text(
            "BRYAN MACKAYNE",
            color = DancerMutedGold,
            fontSize = 10.sp,
            fontWeight = FontWeight.SemiBold,
            letterSpacing = 4.sp,
        )
        Text(
            "The 12 Day Dancer",
            color = DancerCream,
            fontFamily = FontFamily.Serif,
            fontSize = 36.sp,
            fontWeight = FontWeight.Medium,
            textAlign = TextAlign.Center,
            maxLines = 1,
        )
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center,
            modifier = Modifier.widthIn(max = 330.dp),
        ) {
            Box(
                Modifier
                    .weight(1f)
                    .height(1.dp)
                    .background(Brush.horizontalGradient(listOf(Color.Transparent, DancerGold, DancerCream)))
            )
            Text("◆", color = DancerGold, fontSize = 8.sp, modifier = Modifier.padding(horizontal = 9.dp))
            Box(
                Modifier
                    .weight(1f)
                    .height(1.dp)
                    .background(Brush.horizontalGradient(listOf(DancerCream, DancerGold, Color.Transparent)))
            )
        }
    }
}
