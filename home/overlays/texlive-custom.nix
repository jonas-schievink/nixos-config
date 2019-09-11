self: super: {
  texlive-custom = super.texlive.combine {
    inherit (super.texlive) scheme-medium dinbrief;
  };
}
