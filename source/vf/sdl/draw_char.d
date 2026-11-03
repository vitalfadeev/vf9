module vf.sdl.draw_char;

version (SDL):
import vf.sdl.importc_sdl_ttf;
import vf.sdl.exceptions;
import vf.std.color : Color;
import std.string : toStringz;

struct 
Draw_char {
    TTF_Font* font;

    this (string font_file, int font_size) {
        font = open_font (font_file, font_size);
    }

    TTF_Font*
    open_font (string file_name, int font_size) {
        auto filez = file_name.toStringz;
        int  ptsize =font_size;
        auto font = TTF_OpenFont (filez, ptsize);
        //auto font = TTF_OpenFontDPI (filez, ptsize, 102, 102);
        if (font !is null)
            return font;

        throw new TTFException ("TTF_OpenFont");
    }

    SDL_Surface*
    draw_text_old (uint x, uint y, uint w, uint h, Color fg, Color bg, string text, int* size_w,  int* size_h) {
        SDL_Color sdl_fg = cast (SDL_Color) fg.sdl_color;  // struct rgba

        auto surface = TTF_RenderText_Solid (font,text.ptr,text.length,sdl_fg);

        if (surface is null)
            throw new TTFException ("TTF_RenderUTF8_Solid");        

        TTF_GetStringSize (font,text.ptr,text.length,size_w,size_h);

        return surface;
    }
}
