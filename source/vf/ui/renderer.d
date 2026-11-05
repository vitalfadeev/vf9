module vf.ui.renderer;

import vf.std.color        : Color;
import vf.std.xywh : Xywh;
import vf.ui.window;
import std.stdio : writeln;
import std.string : toStringz;   // добавьте в начало модуля или локально
version (SDLTTF) import vf.sdl.fonts;
version (SDLTTF) import vf.sdl.importc_sdl_ttf;

class
Renderer {
    SDL_Renderer* _renderer;
    TTF_TextEngine* _engine;
    // В Renderer
    SDL_Texture* video_texture;
    uint         video_gl_tex;

    this (Window window) {
        _renderer = SDL_CreateRenderer (window._sdl_window,null);
        _engine = TTF_CreateRendererTextEngine(_renderer);
    }

    void
    draw_rect (uint x, uint y, uint w, uint h, Color fg, Color bg) {
        SDL_FRect rect;
        SDL_RenderCoordinatesFromWindow (_renderer, x,y, &rect.x,&rect.y);
        SDL_RenderCoordinatesFromWindow (_renderer, w,h, &rect.w,&rect.h);
        SDL_SetRenderDrawColor (_renderer, bg.r, bg.g, bg.b, bg.a);
        SDL_RenderFillRect (_renderer,&rect);
        SDL_SetRenderDrawColor (_renderer, fg.r, fg.g, fg.b, fg.a);
        SDL_RenderRect (_renderer,&rect);
    }

    void
    draw_text (Font font, string text, int x, int y, int w, int h, Color fg, Color bg) {
        // 2. Создание текстового объекта
        // Передаем 0 в конце, если строка оканчивается нулем (\0)
        TTF_Text* _ttf_text = TTF_CreateText(_engine, font._sdl_font, text.ptr, text.length);

        // Опционально задаем цвет
        TTF_SetTextColor (_ttf_text, fg.r, fg.g, fg.b, fg.a);
        TTF_SetTextString(_ttf_text, text.ptr, text.length);

        // Быстро узнаем текущую длину для выравнивания (например, по центру)
        int _w, _h;
        TTF_GetTextSize(_ttf_text, &_w, &_h);

        float float_x = x;
        float float_y = y;
        TTF_DrawRendererText(_ttf_text, x, y);

        TTF_DestroyText(_ttf_text);
    }

    void
    wh_text (Font font, string text, int* size_w, int* size_h) {
        TTF_Text* _ttf_text = TTF_CreateText(_engine, font._sdl_font, text.ptr, text.length);

        TTF_GetTextSize(_ttf_text, size_w, size_h);
    
        TTF_DestroyText(_ttf_text);
    }

    void
    set_clip_rect (Xywh xywh) {
        SDL_Rect clipRect;
        clipRect.x = xywh.x;
        clipRect.y = xywh.y;
        clipRect.w = xywh.w;
        clipRect.h = xywh.h;
        if (xywh.w && xywh.h)
            SDL_SetRenderClipRect (_renderer, &clipRect);
        else
            SDL_SetRenderClipRect (_renderer, null);
    }

    Xywh
    get_clip_rect () {
        SDL_Rect clipRect;

        SDL_GetRenderClipRect (_renderer, &clipRect);

        Xywh xywh;
        xywh.x = clipRect.x;
        xywh.y = clipRect.y;
        xywh.w = clipRect.w;
        xywh.h = clipRect.h;

        return xywh;
    }

    void
    rasterize () {
        SDL_RenderPresent (_renderer);        
    }


    void create_video_texture(int w, int h) {
        import vf.sdl.importc_sdl;
        video_texture = SDL_CreateTexture(_renderer,
            SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, w, h);
        if (video_texture is null) {
            writeln("SDL_CreateTexture failed: ", SDL_GetError());
            return;
        }
        auto props = SDL_GetTextureProperties(video_texture);
        video_gl_tex = cast(uint) SDL_GetNumberProperty(
            props,
            SDL_PROP_TEXTURE_OPENGL_TEXTURE_NUMBER.toStringz,
            0L
        );
        writeln("video_gl_tex = ", video_gl_tex);
    }

    void draw_video(int x, int y, int w, int h) {
        if (video_texture is null) return;
        SDL_FRect dst;
        dst.x = cast(float)x; dst.y = cast(float)y;
        dst.w = cast(float)w; dst.h = cast(float)h;
        SDL_RenderTexture(_renderer, video_texture, null, &dst);
    }

}
