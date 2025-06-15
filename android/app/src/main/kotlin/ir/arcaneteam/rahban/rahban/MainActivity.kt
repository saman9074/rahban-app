package ir.arcaneteam.rahban.rahban

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.CellInfoGsm
import android.telephony.CellInfoLte
import android.telephony.CellInfoWcdma
import android.telephony.TelephonyManager
import android.Manifest

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.rahban/cellinfo"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "getCellInfo") {
                if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                    val cellInfoMap = getCellInfoMap()
                    if (cellInfoMap != null) {
                        result.success(cellInfoMap)
                    } else {
                        result.error("UNAVAILABLE", "Cell information not available.", null)
                    }
                } else {
                    result.error("PERMISSION_DENIED", "ACCESS_FINE_LOCATION permission not granted.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getCellInfoMap(): Map<String, Any?>? {
        val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        val allCellInfo = telephonyManager.allCellInfo ?: return null

        if (allCellInfo.isEmpty()) {
            return null
        }

        val primaryCell = allCellInfo.firstOrNull { it.isRegistered } ?: allCellInfo.first()

        return when (primaryCell) {
            is CellInfoLte -> {
                val cellIdentity = primaryCell.cellIdentity
                val mcc = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) cellIdentity.mccString else cellIdentity.mcc.toString()
                val mnc = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) cellIdentity.mncString else cellIdentity.mnc.toString()
                // Explicitly define the map type here
                mapOf<String, Any?>(
                    "id" to cellIdentity.ci,
                    "lac" to cellIdentity.tac,
                    "mcc" to mcc,
                    "mnc" to mnc
                )
            }
            is CellInfoGsm -> {
                val cellIdentity = primaryCell.cellIdentity
                val mcc = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) cellIdentity.mccString else cellIdentity.mcc.toString()
                val mnc = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) cellIdentity.mncString else cellIdentity.mnc.toString()
                // Explicitly define the map type here
                mapOf<String, Any?>(
                    "id" to cellIdentity.cid,
                    "lac" to cellIdentity.lac,
                    "mcc" to mcc,
                    "mnc" to mnc
                )
            }
            is CellInfoWcdma -> {
                val cellIdentity = primaryCell.cellIdentity
                val mcc = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) cellIdentity.mccString else cellIdentity.mcc.toString()
                val mnc = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) cellIdentity.mncString else cellIdentity.mnc.toString()
                // Explicitly define the map type here
                mapOf<String, Any?>(
                    "id" to cellIdentity.cid,
                    "lac" to cellIdentity.lac,
                    "mcc" to mcc,
                    "mnc" to mnc
                )
            }
            else -> null
        }
    }
}