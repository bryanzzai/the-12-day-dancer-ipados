package dk.bryanmackayne.the12daydancer.android

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun HomeScreen(
    resources: ResourceStore,
    catalog: DancerCatalog,
    chooseResourceFolder: () -> Unit,
    openAlbum: (AlbumDefinition) -> Unit,
) {
    BoxWithConstraints(Modifier.fillMaxSize()) {
        val facadeSpacerHeight = if (maxHeight >= maxWidth) {
            (maxHeight * 0.89f).coerceAtLeast(270.dp)
        } else {
            (maxHeight * 0.39f).coerceAtLeast(270.dp)
        }

        ResourceImage(
            resources = resources,
            resource = catalog.facadeBackgroundResource,
            modifier = Modifier.fillMaxSize(),
            contentScale = ContentScale.Crop,
        )
        Box(
            Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        listOf(
                            Color.Black.copy(alpha = 0.12f),
                            Color.Black.copy(alpha = 0.10f),
                            Color.Black.copy(alpha = 0.86f),
                        )
                    )
                )
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 10.dp, vertical = 18.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            DancerMast()
            Spacer(Modifier.height(facadeSpacerHeight))
            ConcertConsole(
                resources = resources,
                albums = catalog.albums,
                openAlbum = openAlbum,
                modifier = Modifier.widthIn(max = 430.dp),
            )
            Spacer(Modifier.height(16.dp))
            ResourceFolderPanel(resources, chooseResourceFolder)
            Spacer(Modifier.height(18.dp))
            Text(
                "Bryan MacKayne · The 12 Day Dancer",
                color = Color.White.copy(alpha = 0.42f),
                fontSize = 9.sp,
                letterSpacing = 1.5.sp,
                modifier = Modifier.widthIn(max = 430.dp).fillMaxWidth(),
                textAlign = TextAlign.End,
            )
        }
    }
}

@Composable
private fun ConcertConsole(
    resources: ResourceStore,
    albums: List<AlbumDefinition>,
    openAlbum: (AlbumDefinition) -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .shadow(22.dp, RoundedCornerShape(15.dp))
            .clip(RoundedCornerShape(15.dp))
            .background(
                Brush.linearGradient(
                    listOf(Color(0xFF474A47), Color(0xFF0F1111), Color(0xFF303330))
                )
            )
            .padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Column(
            Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(7.dp))
                .background(Color.Black.copy(alpha = 0.68f))
                .padding(horizontal = 12.dp, vertical = 11.dp),
            verticalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            Text(
                "SELECTIO · XII ALBUM",
                color = Color(0xFFD1B880),
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.7.sp,
            )
            Text(
                "МЕХАНИЧЕН ПУЛТ · РЪЧНО УПРАВЛЕНИЕ",
                color = Color(0xFF8A7D63),
                fontSize = 8.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.1.sp,
            )
        }

        LazyVerticalGrid(
            columns = GridCells.Fixed(2),
            modifier = Modifier.height(((albums.size + 1) / 2 * 148).dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            userScrollEnabled = false,
        ) {
            items(albums, key = { it.slug }) { album ->
                AlbumButton(resources, album, onClick = { openAlbum(album) })
            }
        }
    }
}

@Composable
private fun AlbumButton(resources: ResourceStore, album: AlbumDefinition, onClick: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(9.dp))
            .background(Color.Black)
            .clickable(onClick = onClick),
    ) {
        Box(Modifier.fillMaxWidth().height(92.dp)) {
            ResourceImage(resources, album.bannerResource, Modifier.fillMaxSize())
            Box(
                Modifier.fillMaxSize().background(
                    Brush.horizontalGradient(
                        listOf(Color.Black.copy(alpha = 0.28f), Color.Transparent, Color.Black.copy(alpha = 0.42f))
                    )
                )
            )
            ResourceImage(
                resources,
                album.portraitResource,
                Modifier.width(62.dp).fillMaxHeight(),
                ContentScale.Crop,
            )
        }
        Box(
            Modifier
                .fillMaxWidth()
                .heightIn(min = 44.dp)
                .background(
                    Brush.verticalGradient(listOf(Color(0xFF2E2417), Color(0xFF0D0A08)))
                )
                .padding(horizontal = 5.dp),
            contentAlignment = Alignment.Center,
        ) {
            Text(
                album.title.uppercase(),
                color = Color(0xFFF0DBA8),
                fontSize = 12.sp,
                fontWeight = FontWeight.ExtraBold,
                letterSpacing = 0.7.sp,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                textAlign = TextAlign.Center,
            )
        }
    }
}

@Composable
private fun ResourceFolderPanel(resources: ResourceStore, chooseResourceFolder: () -> Unit) {
    Column(
        modifier = Modifier
            .widthIn(max = 430.dp)
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(Color.Black.copy(alpha = 0.62f))
            .padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(7.dp),
    ) {
        Text(
            if (resources.hasRoot) "LOCAL CONCERT LIBRARY" else "CONNECT CONCERT LIBRARY",
            color = DancerGold,
            fontSize = 10.sp,
            fontWeight = FontWeight.Bold,
            letterSpacing = 1.4.sp,
        )
        Text(
            if (resources.hasRoot) "${resources.rootLabel} · ${resources.indexedResourceCount()} resources"
            else "Choose the existing ConcertResources folder once. Android remembers the permission.",
            color = Color.White.copy(alpha = 0.68f),
            fontSize = 11.sp,
        )
        Button(
            onClick = chooseResourceFolder,
            colors = ButtonDefaults.buttonColors(
                containerColor = Color.White.copy(alpha = 0.10f),
                contentColor = DancerCream,
            ),
        ) {
            Text(if (resources.hasRoot) "CHANGE FOLDER" else "CHOOSE CONCERTRESOURCES")
        }
    }
}
