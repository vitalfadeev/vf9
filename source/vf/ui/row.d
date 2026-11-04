module vf.ui.row;

import std.stdio;
import vf.std.color        : Color;
import vf.ui.control;
import vf.ui.renderer;
import vf.std.xywh                      : Xy,Wh,Xywh;
version (SDL) import vf.sdl.importc_sdl;

class
Row : Control {
    RowArgs  args;
    RowStyle style;
    string id;
    bool _mouse_button_down;
    ON_CLICK_DG on_click;
    alias ON_CLICK_DG = void delegate (Row row, SDL_MouseButtonEvent* evt);

    this (RowArgs args) {
        this.args = args;
        controls = args.controls;
        min_wh.w = 32;
        min_wh.h = 32;
    }
    this (RowArgs args, RowStyle style) {
        this.args = args;
        this.style = style;
        controls = args.controls;
        min_wh.w = 32;
        min_wh.h = 32;
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
        // push draw
        // in draw
        //   xy
        if (style.fixed_wh.w)
            xywh.wh.w = style.fixed_wh.w;
        if (style.fixed_wh.h)
            xywh.wh.h = style.fixed_wh.h;

        if (xywh.wh.w < min_wh.w) {
            xywh.wh.w = min_wh.w;
        }
        if (xywh.wh.h < min_wh.h) {
            xywh.wh.h = min_wh.h;
        }

        Xy xy = xywh.xy;
        xy.x += style.padding_x;
        xy.y += style.padding;
        Wh wh = xywh.wh;
        foreach (c; controls.norecursive) {
            // set c.xy
            c.set_xy (xy);

            // expand width
            if (c.expand)
                c.xywh.w = xywh.w;

            c.update (renderer);

            // next c.xy
            xy.x += c.xywh.w;
            if (xy.x > xywh.w) {
                // reset xy
                xy.y += wh.h;
                xy.x = xywh.x; 
            }
        }
    }

    override
    void
    draw (Renderer renderer) {
        with (xywh)
        if (w > 0 && h > 0)
            renderer.draw_rect (x,y,w,h,style.fg,style.bg);

        //
        foreach (c; controls.norecursive) {
            c.draw (renderer);
        }
    }

    override
    void
    sdl_event_mouse_button_down (SDL_MouseButtonEvent* evt) {
        style.bg = 0xFFCCCCCC;  // 2
        request_update ();

        auto xy = Xy (evt.x, evt.y);
        foreach (c; controls.norecursive) {
            if (c.xywh.has (xy)) {
                c.sdl_event_mouse_button_down (evt);
            }
        }

        _mouse_button_down = true;
    }

    override
    void
    sdl_event_mouse_button_up (SDL_MouseButtonEvent* evt) {
        if (_mouse_button_down) {
            _mouse_button_down = false;

            style.bg = 0xFF222222;  // 2
            request_update ();

            if (on_click)
                on_click (this, evt);

            //
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

struct
RowArgs {
    Control[]          controls;
    MainAxisAlignment  alignment;
    CrossAxisAlignment vertical_alignment;
    int                spacing;
}

struct
RowStyle {
    Color fg = 0xFFFF8888;
    Color bg = 0xFF222222;
    int padding;
    int padding_x = 4;
    Wh  fixed_wh;
}
