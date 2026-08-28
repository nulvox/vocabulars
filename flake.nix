{
  description = "Development environment for the Vocabular Flutter app";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          python = pkgs.python312.withPackages (ps: [
            ps.requests
            ps.beautifulsoup4
            ps.google-auth
          ]);

          # These are needed when running Flutter's Linux desktop target.
          linuxBuildInputs = with pkgs; [
            clang
            cmake
            ninja
            pkg-config
            gtk3
            glib
            pcre2
            libepoxy
            libGL
            libxkbcommon
            wayland
            libx11
            libxcursor
            libxext
            libxi
            libxinerama
            libxrandr
            libxrender
            libxscrnsaver
            libxtst
            alsa-lib
          ];
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.flutterPackages.stable
              python
              pkgs.git
            ] ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux linuxBuildInputs;

            # Flutter plugins and the generated Linux runner use libraries from
            # the host system at build and runtime. Keep this scoped to the
            # development shell rather than changing the project files.
            LD_LIBRARY_PATH = pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux
              (pkgs.lib.makeLibraryPath linuxBuildInputs);

            shellHook = ''
              echo "Vocabular development shell"
              echo "Run: flutter pub get && flutter test"
            '';
          };
        });
    };
}
