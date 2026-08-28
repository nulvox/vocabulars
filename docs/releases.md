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

1. Verifies that the tag is valid and higher than every existing semantic
   release.
2. Derives the Flutter `build-name` and a monotonic Android `build-number`
   from the tag, and writes the same version into `pubspec.yaml` in the build
   workspace.
3. Generates all bundled pronunciation files with the no-login provider.
4. Validates the vocabulary and generated audio.
5. Builds `app-release.apk` with the tag version.
6. Creates a GitHub release and uploads the APK.

A release tag is treated as immutable: the workflow refuses to overwrite an
existing GitHub release or publish a version that is not strictly greater than
an existing release. Repository administrators should also protect `v*` tags
from force updates in GitHub rulesets. Fixes require a new higher version tag.

The generated audio, modified asset list, and generated vocabulary metadata
exist only in the release build workspace; they are not committed as part of
the release workflow. GitHub Actions uses Java 17 and Android API 35 for the
APK build.

## Dry-running the version logic

```bash
printf '[{"tagName":"v1.0.0"}]' >/tmp/releases.json
nix develop --command python scripts/check_release_tag.py \
  --tag v1.1.0 --existing-json /tmp/releases.json
```
