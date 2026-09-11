package dk.bryanmackayne.the12daydancer.android

import androidx.activity.compose.BackHandler
import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalContext

@Composable
fun DancerApp(
    resources: ResourceStore,
    chooseResourceFolder: () -> Unit,
) {
    DancerTheme {
        val context = LocalContext.current
        val catalog = remember { CatalogLoader.load(context) }
        var selectedSlug by rememberSaveable { mutableStateOf<String?>(null) }
        val selected = catalog.albums.firstOrNull { it.slug == selectedSlug }

        if (selected == null) {
            HomeScreen(
                resources = resources,
                catalog = catalog,
                chooseResourceFolder = chooseResourceFolder,
                openAlbum = { selectedSlug = it.slug },
            )
        } else {
            BackHandler { selectedSlug = null }
            when (selected.kind) {
                "video" -> VideoAlbumScreen(
                    resources = resources,
                    album = selected,
                    onBack = { selectedSlug = null },
                )
                else -> AudioAlbumScreen(
                    resources = resources,
                    album = selected,
                    onBack = { selectedSlug = null },
                )
            }
        }
    }
}
