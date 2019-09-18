self: super: {
  lorri = let
    src = super.fetchFromGitHub {
      owner = "target";
      repo = "lorri";
      rev = "a0f21810c7e0476c206d63b80414b0d6111bfafb";
      sha256 = "1y2fvyhlk64idwv8y0smws92bkk51j8z4bagvvlncv3q31147i9n";
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
