self: super: {
  lorri = let
    src = super.fetchFromGitHub {
      owner = "target";
      repo = "lorri";
      rev = "d3e452ebc2b24ab86aec18af44c8217b2e469b2a";
      sha256 = "07yf3gl9sixh7acxayq4q8h7z4q8a66412z0r49sr69yxb7b4q89";
    };

    pkg = import src {
      # Lorri has its own nixpkgs to override the Rust version, so setting
      # `pkgs` isn't required. It requires a recent Rust version to build, so
      # just use the provided nixpkgs.
      #pkgs = super;
    };
  in pkg.overrideAttrs (oldAttrs: rec {
    version = "2019-07-11-unstable";
    name = "lorri-${version}";
  });
}
