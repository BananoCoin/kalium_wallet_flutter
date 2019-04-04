// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.banano.kaliumwallet;

import android.app.Activity;
import android.app.Application;
import androidx.annotation.CallSuper;
import android.content.Context;
import androidx.multidex.MultiDex;

import io.flutter.view.FlutterMain;

/**
 * Flutter implementation of {@link android.app.Application}, managing
 * application-level global initializations.
 */
public class MultidexApplication extends Application {
    @Override
    protected void attachBaseContext(Context base) {
       super.attachBaseContext(base);
       MultiDex.install(this);
    }

    @Override
    @CallSuper
    public void onCreate() {
        super.onCreate();
        FlutterMain.startInitialization(this);
    }

    private Activity mCurrentActivity = null;
    public Activity getCurrentActivity() {
        return mCurrentActivity;
    }
    public void setCurrentActivity(Activity mCurrentActivity) {
        this.mCurrentActivity = mCurrentActivity;
    }
}