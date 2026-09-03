package mihon.core.firebase

import android.content.Context
import com.google.firebase.FirebaseApp
import com.google.firebase.analytics.FirebaseAnalytics
import com.google.firebase.crashlytics.FirebaseCrashlytics

object FirebaseConfig {
    private var analytics: FirebaseAnalytics? = null
    private var crashlytics: FirebaseCrashlytics? = null

    fun init(context: Context) {
        try {
            FirebaseApp.initializeApp(context)
            analytics = FirebaseAnalytics.getInstance(context)
            crashlytics = FirebaseCrashlytics.getInstance()
        } catch (_: Throwable) {
            // Gracefully ignore missing google-services.json in debug or non-GApps environments
        }
    }

    fun setAnalyticsEnabled(enabled: Boolean) {
        try {
            analytics?.setAnalyticsCollectionEnabled(enabled)
        } catch (_: Throwable) {
        }
    }

    fun setCrashlyticsEnabled(enabled: Boolean) {
        try {
            crashlytics?.isCrashlyticsCollectionEnabled = enabled
        } catch (_: Throwable) {
        }
    }
}
