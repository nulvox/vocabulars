# Releases

Releases are created by GitHub Actions from semantic-version tags on `main`.
Use the form `vMAJOR.MINOR.PATCH`:

```bash
git switch main
git pull --ff-only
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin v1.2.0
```

The release workflow then:

1. Verifies that the tag was newly created and was not force-updated.
2. Derives the Flutter `build-name` and a monotonic Android `build-number`
   from the tag, and writes the same version into `pubspec.yaml` in the build
   workspace.
3. Uses the Flutter action for Flutter and bundled Dart, Python for the
   generator, and the Android SDK already present on the GitHub runner.
4. Generates all bundled pronunciation files with the no-login provider.
5. Validates the vocabulary and generated audio.
6. Builds `app-release.apk` with the tag version.
7. Creates a GitHub release and uploads the APK.

A release tag is treated as immutable: the workflow rejects force-updated
or reused tag events and refuses to overwrite an existing GitHub release.
Repository administrators should also protect `v*` tags from force updates in
GitHub rulesets. Fixes require a new version tag.

The generated audio, modified asset list, and generated vocabulary metadata
exist only in the release build workspace; they are not committed as part of
the release workflow. The release uses the Flutter build action and Android API
35 available on the GitHub runner; it does not require Nix. The workflow pins
Flutter 3.47.0, matching the Nix shell and the lockfile, with Gradle 8.7,
Android Gradle Plugin 8.6.1, and Kotlin 2.0.21.

## Dry-running the version logic

```bash
cp pubspec.yaml /tmp/pubspec.yaml
nix develop --command python scripts/check_release_tag.py \
  --tag v1.1.0 --write-pubspec /tmp/pubspec.yaml
```
