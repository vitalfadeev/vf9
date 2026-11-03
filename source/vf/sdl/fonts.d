module vf.sdl.fonts;

version (SDL):
version (SDLTTF):
import std.string : toStringz;
import vf.sdl.importc_sdl_ttf;
import vf.sdl.exceptions;
import vf.sdl.fontconfig : Fontconfig;
import std.format : format;


struct
Fonts {
    Font[] s;

    void
    _init () {
        //
    }

    version (FONTCONFIG)
    TTF_Font*
    open_font (string font_name, int font_size) {
        Fontconfig fc;
        fc._init ();
        auto font_file = fc.select (format!"%s-%d" (font_name,font_size));
        return _open_font (font_file, font_size);
    }

    TTF_Font*
    _open_font (string file_name, int font_size) {
        auto filez = file_name.toStringz;
        int  ptsize =font_size;
        TTF_Font* font = TTF_OpenFont (filez, ptsize);
        //auto font = TTF_OpenFontDPI (filez, ptsize, 102, 102);
        if (font !is null)
            return font;

        throw new TTFException ("TTF_OpenFont");
    }    
}

class
Font {
    TTF_Font* _sdl_font;
    string     file_name;
    int        font_size;

    this (string file_name, int font_size) {
        _sdl_font = fonts._open_font (file_name, font_size);
        fonts.s ~= this;
    }
}

void
_init_fonts () {
    fonts._init ();
    auto font1 = new Font ("res/NotoMonoNerdFont-Regular.ttf", 64);
    auto font2 = new Font ("res/NotoMonoNerdFont-Regular.ttf", 32);
    auto font3 = new Font ("res/NotoMonoNerdFont-Regular.ttf", 16);
    auto font4 = new Font ("res/NotoSansMNerdFont-Bold.ttf", 64);
    auto font5 = new Font ("res/NotoSansMNerdFont-Bold.ttf", 32);
    auto font6 = new Font ("res/NotoSansMNerdFont-Bold.ttf", 16);
}

static
Fonts fonts;
