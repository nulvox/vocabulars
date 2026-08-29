# Releases

Every release builds the configured demos listed in the release workflow
matrix (currently House and Bestiary). Each demo gets its own APK and web
bundle, with content, audio, metadata, and icon selected from its config.

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
4. Selects each demo config in an isolated build job.
5. Generates all bundled pronunciation files with the no-login provider.
6. Validates the vocabulary and generated audio.
7. Builds a versioned APK and web bundle for each demo.
8. Creates one GitHub release and uploads clearly named artifacts for every demo.

A release tag is treated as immutable: the workflow rejects force-updated
or reused tag events and refuses to overwrite an existing GitHub release.
Repository administrators should also protect `v*` tags from force updates in
GitHub rulesets. Fixes require a new version tag.

The generated audio, modified asset list, and generated vocabulary metadata
exist only in each release build workspace; they are not committed as part of
the release workflow. To add another demo, add its config and assets, then add
an entry to the matrix in `.github/workflows/release.yml`. The release uses the Flutter build action and Android API
35 available on the GitHub runner; it does not require Nix. The workflow pins
Flutter 3.47.0, matching the Nix shell and the lockfile, with Gradle 9.5.0,
Android Gradle Plugin 9.3.2, and Kotlin 2.3.20.

## Dry-running the version logic

```bash
cp pubspec.yaml /tmp/pubspec.yaml
nix develop --command python scripts/check_release_tag.py \
  --tag v1.1.0 --write-pubspec /tmp/pubspec.yaml
```
