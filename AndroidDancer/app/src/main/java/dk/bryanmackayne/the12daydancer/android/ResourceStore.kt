package dk.bryanmackayne.the12daydancer.android

import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.documentfile.provider.DocumentFile
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.InputStream

class ResourceStore(private val context: Context) {
    private val prefs = context.getSharedPreferences("dancer-resources", Context.MODE_PRIVATE)
    private var rootUri: Uri? = prefs.getString("tree-uri", null)?.let(Uri::parse)

    @Volatile
    private var index: Map<String, Uri> = emptyMap()

    var revision by mutableIntStateOf(0)
        private set

    val hasRoot: Boolean
        get() = rootUri != null

    val rootLabel: String
        get() = rootUri?.let { uri ->
            DocumentFile.fromTreeUri(context, uri)?.name
        } ?: "No ConcertResources folder selected"

    fun setRoot(uri: Uri) {
        runCatching {
            context.contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
        }
        rootUri = uri
        prefs.edit().putString("tree-uri", uri.toString()).apply()
        index = emptyMap()
        revision += 1
    }

    fun clearRoot() {
        rootUri = null
        prefs.edit().remove("tree-uri").apply()
        index = emptyMap()
        revision += 1
    }

    suspend fun rebuildIndex() {
        val newIndex = withContext(Dispatchers.IO) {
            val root = rootUri ?: return@withContext emptyMap()
            val tree = DocumentFile.fromTreeUri(context, root) ?: return@withContext emptyMap()
            tree.listFiles()
                .asSequence()
                .filter { it.isFile && !it.name.isNullOrBlank() }
                .associate { it.name!! to it.uri }
        }
        index = newIndex
        revision += 1
    }

    fun uriFor(resource: String): Uri? = index[resource]

    fun open(resource: String): InputStream? {
        val uri = index[resource]
        if (uri != null) {
            return runCatching { context.contentResolver.openInputStream(uri) }.getOrNull()
        }
        return runCatching { context.assets.open(resource) }.getOrNull()
    }

    suspend fun image(resource: String): ImageBitmap? = withContext(Dispatchers.IO) {
        open(resource)?.use { stream ->
            BitmapFactory.decodeStream(stream)?.asImageBitmap()
        }
    }

    fun indexedResourceCount(): Int = index.size
}
