package dk.bryanmackayne.the12daydancer.android

import androidx.compose.runtime.Composable

/** Keeps screen state across Android recreation. */
@Composable
fun <T : Any> rememberSaveable(vararg inputs: Any?, init: () -> T): T =
    androidx.compose.runtime.saveable.rememberSaveable(*inputs, init = init)
