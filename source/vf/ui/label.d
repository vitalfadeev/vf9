module vf.ui.label;

import vf.ui.control;
import vf.ui.renderer;
import vf.std.color        : Color;
version (SDL) import vf.sdl.importc_sdl;
version (SDLTTF) import vf.sdl.fonts;

class
Label : Control {
    string  text;

    this (string content, Font font) {
        min_wh.w = 32;
        min_wh.h = 32;

        text = content;
        this.font = font;
    }

    override
    void
    update (Renderer renderer) {
        int size_w;
        int size_h;
        renderer.wh_text (font, text, &size_w, &size_h);
        if (size_w < min_wh.w)
            size_w = min_wh.w;
        if (size_h < min_wh.h)
            size_h = min_wh.h;
        xywh.wh.w = size_w;
        xywh.wh.h = size_h;
    }

    override
    void
    draw (Renderer renderer) {
        Color    fg;
        Color    bg;
        fg = 0xFFFFFFFF;  // 5
        bg = 0xFF888888;  // 2

        with (xywh)
        if (text && font) {
            renderer.draw_text (font,text,x,y,w,h,fg,bg);
        }

        foreach (c; controls.norecursive) {
            c.draw (renderer);
        }
    }
}

