package eu.kanade.presentation.reader.appbars

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import eu.kanade.presentation.components.AppBar

import androidx.compose.ui.tooling.preview.PreviewLightDark
import eu.kanade.presentation.theme.TachiyomiPreviewTheme

@Composable
fun ReaderTopBar(
    mangaTitle: String?,
    chapterTitle: String?,
    navigateUp: () -> Unit,
    // bookmarked: Boolean,
    // onToggleBookmarked: () -> Unit,
    // onOpenInWebView: (() -> Unit)?,
    // onOpenInBrowser: (() -> Unit)?,
    // onShare: (() -> Unit)?,
    modifier: Modifier = Modifier,
) {
    AppBar(
        modifier = modifier,
        backgroundColor = Color.Transparent,
        title = mangaTitle,
        subtitle = chapterTitle,
        navigateUp = navigateUp,
    )
}

@PreviewLightDark
@Composable
private fun ReaderTopBarPreview() {
    TachiyomiPreviewTheme {
        ReaderTopBar(
            mangaTitle = "Sample Manga Title",
            chapterTitle = "Ch. 1 - The Beginning",
            navigateUp = {},
        )
    }
}

