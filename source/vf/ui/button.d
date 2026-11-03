module vf.ui.button;

import std.stdio;
import vf.std.xywh                      : Xy,Wh,Xywh;
import vf.ui.control;
import vf.ui.renderer;
import vf.ui.label;
import vf.std.color        : Color;
version (SDL) import vf.sdl.importc_sdl;
version (SDLTTF) import vf.sdl.fonts;

class
Button : Control {
    ButtonStyle style;
    // delegates
    ON_CLICK_DG on_click;
    alias ON_CLICK_DG = void delegate (Button button, SDL_MouseButtonEvent* evt);

    this (string content) {
        min_wh.w = 32;
        min_wh.h = 32;

        add (new Label (content, fonts.s[5]));
    }

    override
    void
    set_xy (Xy xy) {
        super.set_xy (xy);
        Xy _xy = xy;
        _xy.x += style.padding_x;
        _xy.y += style.padding;
        foreach (c; controls.norecursive)
            c.set_xy (_xy);
    }

    override
    void
    update (Renderer renderer) {
        // wh
        // xy
        // push draw
        foreach (c; controls.norecursive) {
            c.update (renderer);

            xywh.wh = c.xywh.wh;  // from label
            xywh.wh.w += style.padding_x * 2; // left and right
            if (xywh.wh.w < min_wh.w)
                xywh.wh.w = min_wh.w;
            if (xywh.wh.h < min_wh.h)
                xywh.wh.h = min_wh.h;
        }
    }

    override
    void
    draw (Renderer renderer) {
        Color    fg;
        Color    bg;
        fg = 0xFFFFFFFF;  // 5
        bg = 0xFF888888;  // 2

        with (xywh)
        if (w > 0 && h > 0)
            renderer.draw_rect (x,y,w,h,fg,bg);

        foreach (c; controls.norecursive) {
            c.draw (renderer);
        }
    }

    override
    void
    sdl_event_mouse_button_down (SDL_MouseButtonEvent* evt) {
        writeln (this);
        if (on_click)
            on_click (this, evt);
    }
}

struct
ButtonStyle {
    int padding = 3;
    int padding_x = 18;
}
