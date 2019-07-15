# JSON taken from terminal.sexy (Export as "JSON Scheme")

{ dark }: let
  darkJSON = ''
    {
      "name": "",
      "author": "",
      "color": [
        "#1d1f21",
        "#cc342b",
        "#198844",
        "#fba922",
        "#3366cc",
        "#a36ac7",
        "#52a5ff",
        "#c5c8c6",
        "#969896",
        "#cc342b",
        "#198844",
        "#fba922",
        "#3366cc",
        "#a36ac7",
        "#52a5ff",
        "#ffffff"
      ],
      "foreground": "#c5c8c6",
      "background": "#1d1f21"
    }
  '';
  lightJSON = ''
    {
      "name": "",
      "author": "",
      "color": [
        "#1d1f21",
        "#cc342b",
        "#198844",
        "#fba922",
        "#3366cc",
        "#a36ac7",
        "#52a5ff",
        "#c5c8c6",
        "#969896",
        "#cc342b",
        "#198844",
        "#fba922",
        "#3366cc",
        "#a36ac7",
        "#52a5ff",
        "#ffffff"
      ],
      "foreground": "#373b41",
      "background": "#ffffff"
    }
  '';
  stripHash = s:
    assert builtins.stringLength s == 7;
    builtins.substring 1 6 s;
  json = if dark then darkJSON else lightJSON;
  struct = builtins.fromJSON json;
  accents = (map stripHash) struct.color;
  colorN = n: builtins.elemAt accents n;
in {
  foreground = stripHash struct.foreground;
  background = stripHash struct.background;
  colors = accents;

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
