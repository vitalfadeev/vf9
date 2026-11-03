module vf.ui.row;

import vf.std.color        : Color;
import vf.ui.control;
import vf.ui.renderer;
import vf.std.xywh                      : Xy,Wh,Xywh;
version (SDL) import vf.sdl.importc_sdl;

class
Row : Control {
    RowArgs  args;
    RowStyle style;

    this (RowArgs args) {
        this.args = args;
        controls = args.controls;
        min_wh.w = 32;
        min_wh.h = 32;
    }

    override
    void
    set_xy (Xy xy) {
        super.set_xy (xy);
        Xy _xy = xy;
        _xy.x += style.padding * style.padding_x_scale;
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
        xy.x += style.padding * style.padding_x_scale;
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
        Color    fg;
        Color    bg;
        fg = 0xFFFF8888;  // 5
        bg = 0xFF222222;  // 2

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
        auto xy = Xy (evt.x, evt.y);
        foreach (c; controls.norecursive) {
            if (c.xywh.has (xy)) {
                c.sdl_event_mouse_button_down (evt);
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
    int padding;
    int padding_x_scale = 4;
    Wh  fixed_wh;
}
