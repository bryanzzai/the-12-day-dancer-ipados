package dk.bryanmackayne.the12daydancer.android

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

data class TrackDefinition(
    val title: String,
    val mediaResource: String,
    val artworkResource: String,
)

data class FilmDefinition(
    val title: String,
    val mediaResource: String,
    val durationLabel: String,
)

data class AlbumDefinition(
    val roman: String,
    val slug: String,
    val title: String,
    val subtitle: String,
    val description: String,
    val kind: String,
    val bannerResource: String,
    val portraitResource: String,
    val tracks: List<TrackDefinition>,
    val films: List<FilmDefinition>,
)

data class DancerCatalog(
    val sourceCommit: String,
    val facadeBackgroundResource: String,
    val albums: List<AlbumDefinition>,
)

object CatalogLoader {
    fun load(context: Context): DancerCatalog {
        val text = context.assets.open("Catalog.generated.json").bufferedReader().use { it.readText() }
        val root = JSONObject(text)
        val albumsArray = root.getJSONArray("albums")
        val albums = buildList {
            for (i in 0 until albumsArray.length()) {
                add(parseAlbum(albumsArray.getJSONObject(i)))
            }
        }
        return DancerCatalog(
            sourceCommit = root.optString("sourceCommit"),
            facadeBackgroundResource = root.getString("facadeBackgroundResource"),
            albums = albums,
        )
    }

    private fun parseAlbum(o: JSONObject): AlbumDefinition = AlbumDefinition(
        roman = o.getString("roman"),
        slug = o.getString("slug"),
        title = o.getString("title"),
        subtitle = o.getString("subtitle"),
        description = o.getString("description"),
        kind = o.getString("kind"),
        bannerResource = o.getString("bannerResource"),
        portraitResource = o.getString("portraitResource"),
        tracks = parseTracks(o.optJSONArray("tracks") ?: JSONArray()),
        films = parseFilms(o.optJSONArray("films") ?: JSONArray()),
    )

    private fun parseTracks(a: JSONArray): List<TrackDefinition> = buildList {
        for (i in 0 until a.length()) {
            val o = a.getJSONObject(i)
            add(
                TrackDefinition(
                    title = o.getString("title"),
                    mediaResource = o.getString("mediaResource"),
                    artworkResource = o.getString("artworkResource"),
                )
            )
        }
    }

    private fun parseFilms(a: JSONArray): List<FilmDefinition> = buildList {
        for (i in 0 until a.length()) {
            val o = a.getJSONObject(i)
            add(
                FilmDefinition(
                    title = o.getString("title"),
                    mediaResource = o.getString("mediaResource"),
                    durationLabel = o.optString("durationLabel"),
                )
            )
        }
    }
}
