# Example React Native app

This was created using
[`npx create-expo-app@latest`](https://reactnative.dev/docs/environment-setup#start-a-new-react-native-project-with-expo)

Content was taken from the web app example in src/frontend and modified to work
in a React Native environment.

## Get started

Start the OpenTelemetry demo from the root of this repo:

```bash
cd ../..
make start # or start-minimal
```

## Building the app

Unlike the other components under src/ which run within containers this
app must be built and then run on a mobile simulator on your machine or a
physical device. If this is your first time running a React Native app then in
order to execute the steps under "Build on your host machine" you will need to
setup your local environment for Android or iOS development or both following
[this guide](https://reactnative.dev/docs/set-up-your-environment).
Alternatively for Android you can instead follow the steps under "Build within a
container" to leverage a container to build the app's apk for you.

### Build on your host machine

Before building the app you will need to install the dependencies for the app.

```bash
cd src/react-native-app
npm install
```

#### Android: Build and run app

To run on Android, the following command will compile the Android app and deploy
it to a running Android simulator or connected device. It will also start a
a server to provide the JS Bundle required by the app.

```bash
npm run android
```

#### iOS: Setup dependencies

Before building for iOS you will need to setup the iOS dependency management
using CocoaPods. This command only needs to be run the first time before
building the app for iOS.

```bash
cd ios && pod install && cd ..
```

#### iOS: Build and run with XCode

To run on iOS you may find it cleanest to build through the XCode IDE. In order
to start a server to provide the JS Bundle, run the following command (feel free
to ignore the output commands referring to opening an iOS simulator, we'll do
that directly through XCode in the next step).

```bash
npm run start
```

Then open XCode, open this as an existing project by opening
`src/react-native-app/ios/react-native-app.xcworkspace` then trigger the build
by hitting the Play button or from the menu using Product->Run.

#### iOS: Build and run from the command-line

You can build and run the app using the command line with the following
command. This will compile the iOS app and deploy it to a running iOS simulator
and start a server to provide the JS Bundle.

```bash
npm run ios
```

### Build within a container

For Android builds you can produce an apk using Docker without requiring the dev
tools to be installed on your host. From this repository root run the
following command.

```bash
make build-react-native-android
```

Or directly from this folder using.

```bash
docker build -f android.Dockerfile --platform=linux/amd64 --output=. .
```

This will create a `react-native-app.apk` file in the directory where you ran
the command. If you have an Android emulator running on your machine then you
can drag and drop this file onto the emulator's window in order to install it.

## Bazel (Android only — **no iOS**)

This package has **Bazel** targets (**BZ-096**) for **continuous checks** and an optional **debug APK** build. **iOS** / **CocoaPods** / **Xcode** are **not** wired in Bazel (by design).

### Hermetic Android SDK vs SDKMAN / host JDK

| Piece | What Bazel uses | Notes |
|-------|-----------------|--------|
| **Android SDK + NDK** | **`@rn_android_sdk`** — a **`repository_rule`** in **`tools/bazel/rn_android/sdk_repo.bzl`** downloads **Temurin 17**, **Android cmdline-tools**, then runs **`sdkmanager`** for **API 34**, **build-tools 34.0.0**, **NDK 26.1.10909125** (aligned with **`android/build.gradle`**). | **Linux x86_64 only** today. First resolution can take **tens of minutes** and **~2+ GB** disk; results live under Bazel’s external cache. **Not** your `~/Android/Sdk` unless you ignore this path. |
| **JDK for Gradle inside `android_debug_apk`** | **`JAVA_HOME=$SDK_BUNDLE/jdk`** from **`@rn_android_sdk`** | **Independent of SDKMAN.** If you use **SDKMAN** for daily development (`gradle`, `java` on **`PATH`**), that is fine for **`npm run android`** / Android Studio — Bazel’s APK rule does **not** read **`~/.sdkman/candidates/java`**. |
| **Node / npm** | **Host** toolchain (**Node 18+** required by Expo 51; CI uses **22**) | **`npm ci`** runs inside actions; **`requires-network`**. |
| **Gradle caches** | **`GRADLE_USER_HOME`** and **`NPM_CONFIG_CACHE`** are **temp dirs** inside the action | Avoids polluting **`~/.gradle`**; each build is isolated aside from **`@rn_android_sdk`**. |

### Targets

| Target | Purpose |
|--------|---------|
| **`//src/react-native-app:rn_js_checks`** | **`sh_test`**: **`npm ci`**, **`tsc --noEmit`**, **`jest --ci --passWithNoTests`**. Tags **`unit`**, **`requires-network`**, **`size = enormous`**. |
| **`//src/react-native-app:android_debug_apk`** | **`rn_android_debug_apk`**: copy app → **`npm ci`** → **`./gradlew :app:assembleDebug`** → **`app-debug.apk`**. Tags **`manual`**, **`no-sandbox`**, **`requires-network`**. Triggers **`@rn_android_sdk`** fetch on first use. |

```bash
# Fast path (CI): JS/TS checks only
bazel test //src/react-native-app:rn_js_checks --config=ci

# Optional: debug APK (Linux x86_64; long first run while @rn_android_sdk populates)
bazel build //src/react-native-app:android_debug_apk --config=ci
```

**Tracked `expo-env.d.ts`:** checked in so **`tsc`** works without **`expo start`** (see **`.gitignore`** comment).

**Alternate build:** **`make build-react-native-android`** / **`android.Dockerfile`** remains the containerized APK path.

---

## Pointing to another demo environment

By default, the app will point to `EXPO_PUBLIC_FRONTEND_PROXY_PORT` on
localhost to interact with the demo APIs. This can be changed in the Settings
tab when running the app to point to a demo environment running on a
different server.

## Troubleshooting

### JS Bundle: build issues

Try removing the `src/react-native-app/node_modules/` folder and then re-run
`npm install` from inside `src/react-native-app`.

### Android: build app issues

Try stopping and cleaning local services (in case there are unknown issues
related to the start of the app).

```bash
cd src/react-native-app/android
./gradlew --stop  // stop daemons
rm -rf ~/.gradle/caches/
```

### iOS: pod install issues

Note that the above is the quickest way to get going but you may end up with
slightly different versions of the Pods than what has been committed to this
repository, in order to install the precise versions first setup
[rbenv](https://github.com/rbenv/rbenv#installation) followed by the following
commands.

```bash
rbenv install 2.7.6 # the version of ruby we've pinned for this app
bundle install
cd ios
bundle exec pod install
```

### iOS: build app issues

If you see a build failure related to pods try forcing a clean install with and
then attempt another build after:

```bash
  cd src/react-native-app/ios
  rm Podfile.lock
  pod cache clean --all
  pod repo update --verbose
  pod deintegrate
  pod install --repo-update --verbose
```

If there is an error compiling or running the app try closing any open
simulators and clearing all derived data:

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```
