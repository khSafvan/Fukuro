package tachiyomi.domain.category.model

import androidx.compose.runtime.Immutable
import java.io.Serializable

@Immutable
data class Category(
    val id: Long,
    val name: String,
    val order: Long,
    val flags: Long,
    val version: Long = 0,
    val uid: Long = 0,
    val lastModifiedAt: Long = 0,
) : Serializable {

    val isSystemCategory: Boolean = id == UNCATEGORIZED_ID

    companion object {
        const val UNCATEGORIZED_ID = 0L
    }
}
