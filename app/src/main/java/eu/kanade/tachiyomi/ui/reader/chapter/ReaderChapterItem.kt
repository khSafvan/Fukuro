package eu.kanade.tachiyomi.ui.reader.chapter

import androidx.compose.runtime.Immutable
import tachiyomi.domain.chapter.model.Chapter
import tachiyomi.domain.manga.model.Manga
import java.time.format.DateTimeFormatter

@Immutable
data class ReaderChapterItem(
    val chapter: Chapter,
    val manga: Manga,
    val isCurrent: Boolean,
    val dateFormat: DateTimeFormatter,
)
