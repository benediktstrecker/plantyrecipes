package com.example.planty_flutter_starter

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.os.Bundle
import android.widget.FrameLayout
import com.airbnb.lottie.LottieAnimationView
import com.airbnb.lottie.LottieDrawable
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterView

class MainActivity : FlutterActivity() {

    private lateinit var container: FrameLayout
    private lateinit var splash: LottieAnimationView
    private lateinit var flutterView: FlutterView

    override fun onStart() {
        super.onStart()

        container = FrameLayout(this).apply {
            setBackgroundColor(android.graphics.Color.parseColor("#112A1D"))
        }

        splash = LottieAnimationView(this).apply {
            setAnimation("leaf_animation.json")
            repeatCount = 0
            playAnimation()
        }

        container.addView(splash)
        window.setContentView(container)

        flutterView = FlutterView(this).apply { alpha = 0f }
        flutterEngine?.let { flutterView.attachToFlutterEngine(it) }

        splash.addAnimatorListener(object : AnimatorListenerAdapter() {
            override fun onAnimationEnd(animation: Animator) {
                setContentView(flutterView)
                flutterView.animate()
                    .alpha(1f)
                    .setDuration(250)
                    .start()
            }
        })
    }
}
