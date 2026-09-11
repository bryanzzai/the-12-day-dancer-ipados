package dk.bryanmackayne.the12daydancer.android

import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    private lateinit var resources: ResourceStore

    private val folderPicker = registerForActivityResult(ActivityResultContracts.OpenDocumentTree()) { uri: Uri? ->
        if (uri != null) {
            resources.setRoot(uri)
            lifecycleScope.launch { resources.rebuildIndex() }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        resources = ResourceStore(this)
        lifecycleScope.launch { resources.rebuildIndex() }

        setContent {
            DancerApp(
                resources = resources,
                chooseResourceFolder = { folderPicker.launch(null) },
            )
        }
    }
}
