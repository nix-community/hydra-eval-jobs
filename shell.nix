{
  pkgs ? (
    let
      inherit (builtins) fromJSON readFile;
      flakeLock = fromJSON (readFile ./flake.lock);
      inherit (flakeLock.nodes.nixpkgs) locked;
      nixpkgs =
        assert locked.type == "github";
        builtins.fetchTarball {
          url = "https://github.com/${locked.owner}/${locked.repo}/archive/${locked.rev}.tar.gz";
          sha256 = locked.narHash;
        };
    in
    import nixpkgs { }
  ),
  stdenv ? pkgs.stdenv,
  lib ? pkgs.lib,
  srcDir ? null,
  nix,
}:

let
  nix-eval-jobs = pkgs.callPackage ./default.nix { inherit srcDir nix; };
in
(pkgs.mkShell.override { inherit stdenv; }) {
  inherit (nix-eval-jobs) buildInputs;
  nativeBuildInputs = nix-eval-jobs.nativeBuildInputs ++ [
    (pkgs.python3.withPackages (ps: [ ps.pytest ]))
    (lib.hiPrio pkgs.llvmPackages_latest.clang-tools)
  ];

  shellHook = lib.optionalString (stdenv.isLinux && nix ? debug) ''
    export NIX_DEBUG_INFO_DIRS="${pkgs.curl.debug}/lib/debug:${nix.debug}/lib/debug''${NIX_DEBUG_INFO_DIRS:+:$NIX_DEBUG_INFO_DIRS}"
  '';
}
