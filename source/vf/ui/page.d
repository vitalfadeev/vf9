module vf.ui.page;

import std.stdio;
import vf.std.xywh                      : Xy,Wh,Xywh;
import vf.std.color        : Color;
import vf.ui.control;
import vf.ui.row;
import vf.ui.renderer;
version (SDL) import vf.sdl.importc_sdl;

class
Page : Control {
    this () {
        min_wh.w = 32;
        min_wh.h = 32;
    }

    override
    void
    set_xy (Xy xy) {
        super.set_xy (xy);
        foreach (c; controls.norecursive)
            c.set_xy (xy);
    }

    override
    void
    update (Renderer renderer) {
        // wh
        // push draw
        // in draw
        //   xy
        if (xywh.wh.h < min_wh.h) {
            xywh.wh.h = min_wh.h;
        }
        if (xywh.wh.w < min_wh.w) {
            xywh.wh.w = min_wh.w;
        }

        Xy xy = xywh.xy;
        foreach (/* Row */ c; controls.norecursive) {
            // set c.xy
            c.set_xy (xy);
            c.xywh.w = xywh.w;

            c.update (renderer);

            // next c.xy
            xy.y += c.xywh.h;
        }
    }

    override
    void
    draw (Renderer renderer) {
        Color    fg;
        Color    bg;
        fg = 0xFF22FF22;  // 5
        bg = 0xFF111111;  // 2

        with (xywh)
        if (w > 0 && h > 0)
            renderer.draw_rect (x,y,w,h,fg,bg);

        //
        foreach (c; controls.norecursive) {
            c.draw (renderer);
        }
    }

    override
    void
    sdl_event_mouse_button_down (SDL_MouseButtonEvent* evt) {
        with (evt) {
            auto xy = Xy (evt.x, evt.y);
            foreach (c; controls.norecursive) {
                if (c.xywh.has (xy)) {
                    c.sdl_event_mouse_button_down (evt);
                }
            }
        }
    }

    override
    void
    sdl_event_mouse_button_up (SDL_MouseButtonEvent* evt) {
        with (evt) {
            auto xy = Xy (evt.x, evt.y);
            foreach (c; controls.norecursive) {
                if (c.xywh.has (xy)) {
                    c.sdl_event_mouse_button_up (evt);
                }
            }
        }
    }

    override
    void
    sdl_event_mouse_wheel (SDL_MouseWheelEvent* evt) {
        auto xy = Xy (evt.mouse_x, evt.mouse_y);
        foreach (c; controls.norecursive) {
            if (c.xywh.has (xy)) {
                c.sdl_event_mouse_wheel (evt);
            }
        }
    }
}
