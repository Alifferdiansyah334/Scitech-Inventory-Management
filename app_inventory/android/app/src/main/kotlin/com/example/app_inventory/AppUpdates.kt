package com.example.app_inventory

import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.URL
import java.security.MessageDigest
import java.util.concurrent.Executors
import javax.net.ssl.HttpsURLConnection

/** APK bytes never leave this application's private cache until Android installs them. */
class AppUpdates(private val activity: MainActivity, private val channel: MethodChannel) {
    private val worker = Executors.newSingleThreadExecutor()
    @Volatile private var downloading = false
    private data class VerifiedPackage(val file: File, val hash: String, val version: Long, val bytes: Long)
    private var verified: VerifiedPackage? = null
    private val maxBytes = 150L * 1024 * 1024

    @Suppress("DEPRECATION")
    private fun installed(): PackageInfo = activity.packageManager.getPackageInfo(activity.packageName, signatureFlags())
    private fun signatureFlags(): Int = if (Build.VERSION.SDK_INT >= 28) PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES
    @Suppress("DEPRECATION")
    private fun version(info: PackageInfo): Long = if (Build.VERSION.SDK_INT >= 28) info.longVersionCode else info.versionCode.toLong()
    private fun sha(bytes: ByteArray) = MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }
    @Suppress("DEPRECATION")
    private fun certificates(info: PackageInfo): Set<String> = if (Build.VERSION.SDK_INT >= 28) {
        info.signingInfo?.apkContentsSigners?.map { sha(it.toByteArray()) }?.toSet() ?: emptySet()
    } else info.signatures?.map { sha(it.toByteArray()) }?.toSet() ?: emptySet()
    private fun fileHash(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        file.inputStream().buffered().use { input ->
            val buffer = ByteArray(65536)
            while (true) { val count = input.read(buffer); if (count < 0) break; digest.update(buffer, 0, count) }
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
    }

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "installedRelease" -> {
                val info = installed()
                result.success(mapOf("version" to (info.versionName ?: ""), "build_number" to version(info)))
            }
            "downloadUpdate" -> download(call, result)
            "installUpdate" -> install(result)
            "openInstallPermission" -> {
                try {
                    if (Build.VERSION.SDK_INT >= 26) {
                        activity.startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:${activity.packageName}")))
                    }
                    result.success(null)
                } catch (_: Exception) { result.error("PERMISSION_UNAVAILABLE", "Pengaturan izin belum dapat dibuka.", null) }
            }
            else -> result.notImplemented()
        }
    }

    private fun sameOrigin(a: URL, b: URL): Boolean = a.protocol == "https" && b.protocol == "https" &&
        a.host.equals(b.host, ignoreCase = true) && a.effectivePort() == b.effectivePort() && a.userInfo == null && b.userInfo == null
    private fun URL.effectivePort() = if (port == -1) defaultPort else port

    private fun download(call: MethodCall, result: MethodChannel.Result) {
        if (downloading) { result.error("BUSY", "Tunggu unduhan sebelumnya selesai.", null); return }
        val source = call.argument<String>("url")
        val origin = call.argument<String>("origin")
        val hash = call.argument<String>("sha256")
        val expectedVersion = call.argument<Number>("build_number")?.toLong()
        val expectedBytes = call.argument<Number>("size_bytes")?.toLong()
        try {
            require(source != null && origin != null && hash != null && Regex("^[a-f0-9]{64}$").matches(hash))
            val url = URL(source); val base = URL(origin)
            require(sameOrigin(url, base) && base.path in listOf("", "/") && base.query == null && base.ref == null)
            require(url.query == null && url.ref == null && Regex("^/releases/[A-Za-z0-9][A-Za-z0-9._+\\-]*\\.apk$").matches(url.path))
            require(expectedVersion != null && expectedVersion > version(installed()))
            require(expectedBytes != null && expectedBytes in 1..maxBytes)
            verified = null; downloading = true
            worker.execute {
                val directory = File(activity.cacheDir, "updates"); directory.mkdirs()
                val partial = File(directory, "update.apk.part")
                val target = File(directory, "update.apk")
                try {
                    require(directory.usableSpace >= expectedBytes + 10 * 1024 * 1024)
                    val started = System.nanoTime()
                    var current = url
                    var connection: HttpsURLConnection? = null
                    try {
                        for (redirect in 0..3) {
                            require(sameOrigin(current, base) && current.ref == null && current.query == null)
                            val candidate = current.openConnection() as HttpsURLConnection
                            connection = candidate
                            candidate.instanceFollowRedirects = false
                            candidate.connectTimeout = 15000; candidate.readTimeout = 30000
                            candidate.setRequestProperty("Accept-Encoding", "identity")
                            val code = candidate.responseCode
                            if (code in listOf(301, 302, 303, 307, 308)) {
                                val location = candidate.getHeaderField("Location") ?: error("Missing redirect")
                                current = URL(current, location)
                                candidate.disconnect(); connection = null
                                require(redirect < 3)
                                continue
                            }
                            require(code == 200)
                            require(candidate.contentLengthLong == -1L || candidate.contentLengthLong == expectedBytes)
                            var count = 0L; var lastProgress = -1
                            candidate.inputStream.buffered().use { input ->
                                partial.outputStream().buffered().use { output ->
                                    val buffer = ByteArray(65536)
                                    while (true) {
                                        require(System.nanoTime() - started < 300_000_000_000L)
                                        val read = input.read(buffer); if (read < 0) break
                                        count += read; require(count <= expectedBytes && count <= maxBytes)
                                        output.write(buffer, 0, read)
                                        val progress = (count * 100 / expectedBytes).toInt()
                                        if (progress != lastProgress) {
                                            lastProgress = progress
                                            activity.runOnUiThread { channel.invokeMethod("downloadProgress", progress) }
                                        }
                                    }
                                }
                            }
                            require(count == expectedBytes && fileHash(partial) == hash)
                            require(!target.exists() || target.delete())
                            require(partial.renameTo(target))
                            val value = VerifiedPackage(target, hash, expectedVersion, expectedBytes)
                            verify(value)
                            verified = value
                            activity.runOnUiThread { result.success(true) }
                            return@execute
                        }
                        error("Download failed")
                    } finally { connection?.disconnect() }
                } catch (_: Exception) {
                    partial.delete(); target.delete(); verified = null
                    activity.runOnUiThread { result.error("UPDATE_REJECTED", "Paket belum dapat diunduh atau gagal diverifikasi. Tidak ada pembaruan yang dipasang.", null) }
                } finally { downloading = false }
            }
        } catch (_: Exception) {
            result.error("INVALID_RELEASE", "Sumber atau versi pembaruan tidak diizinkan.", null)
        }
    }

    @Suppress("DEPRECATION")
    private fun verify(value: VerifiedPackage) {
        require(value.file.isFile && value.file.length() == value.bytes && fileHash(value.file) == value.hash)
        val archive = activity.packageManager.getPackageArchiveInfo(value.file.absolutePath, signatureFlags()) ?: error("Invalid APK")
        val current = installed()
        require(archive.packageName == activity.packageName && version(archive) == value.version && value.version > version(current))
        val signatures = certificates(archive)
        require(signatures.isNotEmpty() && signatures == certificates(current))
    }

    private fun install(result: MethodChannel.Result) {
        val value = verified
        if (downloading || value == null) { result.error("NOT_READY", "Unduh dan verifikasi paket terlebih dahulu.", null); return }
        if (Build.VERSION.SDK_INT >= 26 && !activity.packageManager.canRequestPackageInstalls()) {
            result.success("permission_required"); return
        }
        worker.execute {
            try {
                verify(value)
                val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.updates", value.file)
                activity.runOnUiThread {
                    try {
                        val intent = Intent(Intent.ACTION_VIEW).setDataAndType(uri, "application/vnd.android.package-archive")
                        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        activity.startActivity(intent)
                        result.success("installer_opened")
                    } catch (_: Exception) { result.error("INSTALLER_UNAVAILABLE", "Pemasang Android belum dapat dibuka.", null) }
                }
            } catch (_: Exception) {
                verified = null; value.file.delete()
                activity.runOnUiThread { result.error("UPDATE_REJECTED", "Identitas, versi, checksum, atau tanda tangan paket tidak sesuai. Pemasangan ditolak.", null) }
            }
        }
    }
}
