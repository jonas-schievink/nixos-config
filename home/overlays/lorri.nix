self: super: {
  lorri = let
    src = super.fetchFromGitHub {
      owner = "target";
      repo = "lorri";

      # To update, use the latest commit on the `rolling-release` branch
      rev = "38eae3d487526ece9d1b8c9bb0d27fb45cf60816";
      sha256 = "11k9lxg9cv6dlxj4haydvw4dhcfyszwvx7jx9p24jadqsy9jmbj4";
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
