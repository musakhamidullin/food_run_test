package ru.foodrun.client

import android.app.Application
import io.flutter.embedding.android.FlutterActivity
import com.yandex.mapkit.MapKitFactory

class MainActivity : FlutterActivity()

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MapKitFactory.setApiKey("3d7a1e4f-8b2c-4a9d-b5f1-2e8c7d3a9b4f")
    }
}
