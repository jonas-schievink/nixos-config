{ dark }: let
  colorsDark = {
    foreground = "c5c8c6";
    foregroundAlt = "969896";
    background = "1d1f21";
    backgroundAlt = "383c40";

    colors = [
      "1d1f21"
      "cc342b"
      "198844"
      "fba922"
      "3366cc"
      "a36ac7"
      "52a5ff"
      "c5c8c6"
      "969896"
      "cc342b"
      "198844"
      "fba922"
      "3366cc"
      "a36ac7"
      "52a5ff"
      "ffffff"
    ];
  };
  colorsLight = {
    foreground = "373b41";
    foregroundAlt = "656765";
    background = "e2e5e3";
    backgroundAlt = "cdd0ce";

    colors = [
      "1d1f21"
      "cc342b"
      "198844"
      "fba922"
      "3366cc"
      "a36ac7"
      "52a5ff"
      "c5c8c6"
      "969896"
      "cc342b"
      "198844"
      "fba922"
      "3366cc"
      "a36ac7"
      "52a5ff"
      "ffffff"
    ];
  };

  color = if dark then colorsDark else colorsLight;
  colorN = n: builtins.elemAt color.colors n;
in color // {
  black     = colorN 0;
  white     = colorN 15;
  red       = colorN 1;
  green     = colorN 2;
  yellow    = colorN 3;
  darkBlue  = colorN 4;
  lightBlue = colorN 6;
  darkGray  = colorN 8;
  lightGray = colorN 7;
}
