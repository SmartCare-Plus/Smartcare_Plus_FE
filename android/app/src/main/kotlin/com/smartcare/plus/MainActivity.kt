package com.smartcare.plus

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.RandomAccessFile
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterActivity() {
    private val channelName = "smartcare_plus/audio_recorder"
    private val sampleRate = 16000
    private var recorder: AudioRecord? = null
    private var recordingThread: Thread? = null
    private var outputFile: File? = null
    private val isRecording = AtomicBoolean(false)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrBlank()) {
                            result.error("invalid_path", "Audio path is required", null)
                        } else {
                            startRecording(path, result)
                        }
                    }
                    "stop" -> stopRecording(result)
                    "cancel" -> {
                        stopRecording(null)
                        outputFile?.delete()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startRecording(path: String, result: MethodChannel.Result) {
        if (isRecording.get()) {
            result.error("already_recording", "Recording is already active", null)
            return
        }

        val minBuffer = AudioRecord.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        if (minBuffer <= 0) {
            result.error("recorder_unavailable", "Microphone recorder is unavailable", null)
            return
        }

        try {
            val file = File(path)
            file.parentFile?.mkdirs()
            writeWavHeader(file, 0)

            val audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                sampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                minBuffer * 2
            )
            audioRecord.startRecording()

            outputFile = file
            recorder = audioRecord
            isRecording.set(true)

            recordingThread = Thread {
                val buffer = ByteArray(minBuffer)
                RandomAccessFile(file, "rw").use { raf ->
                    raf.seek(44)
                    while (isRecording.get()) {
                        val read = audioRecord.read(buffer, 0, buffer.size)
                        if (read > 0) {
                            raf.write(buffer, 0, read)
                        }
                    }
                    val audioSize = raf.length() - 44
                    raf.seek(0)
                    raf.write(buildWavHeader(audioSize))
                }
            }
            recordingThread?.start()
            result.success(null)
        } catch (e: SecurityException) {
            result.error("permission_denied", "Microphone permission denied", null)
        } catch (e: Exception) {
            result.error("start_failed", e.message, null)
        }
    }

    private fun stopRecording(result: MethodChannel.Result?) {
        if (!isRecording.get()) {
            result?.success(outputFile?.absolutePath)
            return
        }

        isRecording.set(false)
        try {
            recorder?.stop()
        } catch (_: Exception) {
        }
        try {
            recordingThread?.join(1500)
        } catch (_: InterruptedException) {
        }
        recorder?.release()
        recorder = null
        recordingThread = null
        result?.success(outputFile?.absolutePath)
    }

    private fun writeWavHeader(file: File, audioSize: Long) {
        RandomAccessFile(file, "rw").use { raf ->
            raf.setLength(0)
            raf.write(buildWavHeader(audioSize))
        }
    }

    private fun buildWavHeader(audioSize: Long): ByteArray {
        val totalSize = audioSize + 36
        val byteRate = sampleRate * 2
        return byteArrayOf(
            'R'.code.toByte(), 'I'.code.toByte(), 'F'.code.toByte(), 'F'.code.toByte(),
            (totalSize and 0xff).toByte(), ((totalSize shr 8) and 0xff).toByte(),
            ((totalSize shr 16) and 0xff).toByte(), ((totalSize shr 24) and 0xff).toByte(),
            'W'.code.toByte(), 'A'.code.toByte(), 'V'.code.toByte(), 'E'.code.toByte(),
            'f'.code.toByte(), 'm'.code.toByte(), 't'.code.toByte(), ' '.code.toByte(),
            16, 0, 0, 0, 1, 0, 1, 0,
            (sampleRate and 0xff).toByte(), ((sampleRate shr 8) and 0xff).toByte(),
            ((sampleRate shr 16) and 0xff).toByte(), ((sampleRate shr 24) and 0xff).toByte(),
            (byteRate and 0xff).toByte(), ((byteRate shr 8) and 0xff).toByte(),
            ((byteRate shr 16) and 0xff).toByte(), ((byteRate shr 24) and 0xff).toByte(),
            2, 0, 16, 0,
            'd'.code.toByte(), 'a'.code.toByte(), 't'.code.toByte(), 'a'.code.toByte(),
            (audioSize and 0xff).toByte(), ((audioSize shr 8) and 0xff).toByte(),
            ((audioSize shr 16) and 0xff).toByte(), ((audioSize shr 24) and 0xff).toByte()
        )
    }
}
