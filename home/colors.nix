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
  colors = builtins.fromJSON json;
in {
  foreground = stripHash colors.foreground;
  background = stripHash colors.background;
  colors = (map stripHash) colors.color;
}
