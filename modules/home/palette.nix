# Two palettes are live. `inkCream` colours the terminal side: kitty,
# starship, nvim, gazelle and the window borders. `night` is the shell's
# wallpaper palette; it mirrors quickshell/config/Theme.qml, which cannot
# import from here, so change both together.
{
  inkCream = {
    base = "#1d1c24";
    surface = "#24232c";
    raised = "#36343f";
    track = "#3d3a4f";
    ink = "#0f0e13";

    bright = "#ece6d8";
    text = "#9b97ad";
    muted = "#6b6780";

    yellow = "#e6c88a";
    red = "#e89a8a";
    green = "#9fd3a3";
    blue = "#9ab4e0";
    magenta = "#c9a6e0";
    cyan = "#9fd3cf";
  };

  night = {
    surface = "#1a2533";
    ink = "#080c12";
    bright = "#e8eef2";
    text = "#8fa6bf";
    accent = "#aebcf0";
    red = "#e0948a";
  };
}
