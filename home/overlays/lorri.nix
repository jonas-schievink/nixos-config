self: super: {
  lorri = let
    src = super.fetchFromGitHub {
      owner = "target";
      repo = "lorri";

      # To update, use the latest commit on the `rolling-release` branch
      rev = "03f10395943449b1fc5026d3386ab8c94c520ee3";
      sha256 = "0fcl79ndaziwd8d74mk1lsijz34p2inn64b4b4am3wsyk184brzq";
    };

    pkg = import src {
      # Lorri has its own nixpkgs to override the Rust version, so setting
      # `pkgs` isn't required. It requires a recent Rust version to build, so
      # just use the provided nixpkgs.
      #pkgs = super;
    };
  in pkg.overrideAttrs (oldAttrs: rec {
    version = "2019-09-18-unstable";
    name = "lorri-${version}";
  });
}
