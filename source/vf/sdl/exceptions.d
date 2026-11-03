module vf.sdl.exceptions;

version (SDL):
import std.format         : format;
import std.conv           : to;
import vf.sdl.importc_sdl : SDL_GetError;


class 
SDLException : Exception {
    this (string msg) {
        super (format!"%s: %s" (SDL_GetError().to!string, msg));
    }
}

version (SDLTTF)
class 
TTFException : Exception{
    this (string s) {
        import std.string : fromStringz;
        //import vf.sdl.importc_sdl_ttf : TTF_GetError;
        super (
            // format!"%s: %s"(s, fromStringz(TTF_GetError()))
            format!"%s: %s"(s, fromStringz(SDL_GetError()))
        );
    }
}

version (SDLImage)
class 
IMGException : Exception{
    this (string s) {
        import std.string : fromStringz;
        super (
            format!"%s: %s"(s, fromStringz(IMG_GetError()))
        );
    }
}

version (SDLMIXER)
class 
MixException : Exception{
    this (string s) {
        import vf.sdl.importc_sdl_mixer;
        import std.string : fromStringz;
        alias Mix_GetError = SDL_GetError;
        super (
            format!"%s: %s"(s, fromStringz(Mix_GetError()))
        );
    }
}
