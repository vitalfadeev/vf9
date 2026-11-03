module vf.ui.listview;

import std.stdio;
import vf.std.xywh                      : Xy,Wh,Xywh;
import vf.ui.renderer;
import vf.ui.control;
import vf.ui.label;
import vf.ui.row;
import vf.std.color        : Color;
import std.conv : to;
version (SDL) import vf.sdl.importc_sdl;
version (SDLTTF) import vf.sdl.fonts;
const float SCROLL_SENSITIVITY = 25.0f; 

class
ListView : Control {
    ListViewArgs args;
    ListStyle style;
    int scroll_y;
    // delegates
    ON_CLICK_DG on_click;
    alias ON_CLICK_DG = void delegate (ListView listview, SDL_MouseButtonEvent* evt);

    this (ListViewArgs args) {
        min_wh.w = 32;
        min_wh.h = 32;
        this.args = args;
        xywh.h = args.height;
        expand = args.expand;
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
        // xy
        // push draw
        if (xywh.wh.w < min_wh.w) {
            xywh.wh.w = min_wh.w;
        }
        if (xywh.wh.h < min_wh.h) {
            xywh.wh.h = min_wh.h;
        }

        Xy xy = xywh.xy;
        xy.y += scroll_y;
        foreach (c; controls.norecursive) {
            // set c.xy
            c.set_xy (xy);
            c.xywh.w = xywh.w;

            c.update (renderer);

            // next c.xy
            xy.y += c.xywh.h;  
            xy.y -= 1;// merge borders
        }
    }

    override
    void
    draw (Renderer renderer) {
        Color    fg;
        Color    bg;
        fg = 0xFF3333FF;  // 5
        bg = 0xFF888888;  // 2

        with (xywh)
        if (w > 0 && h > 0)
            renderer.draw_rect (x,y,w,h,fg,bg);

        // clipped
        auto old_clip = renderer.get_clip_rect ();
        renderer.set_clip_rect (xywh);

        foreach (c; controls.norecursive) {
            c.draw (renderer);
        }

        renderer.set_clip_rect (old_clip);

        // ScrollBar
        draw_scrollbar (renderer);
    }

    void
    draw_scrollbar (Renderer renderer) {
        int sb_w = 32;
        int sb_h = xywh.h;
        int sb_x = xywh.w - sb_w;
        int sb_y = xywh.y;

        Color    fg;
        Color    bg;
        fg = 0xFFCCCCCC;  // 5
        bg = 0xFFAAAAAA;  // 2

        if (sb_w > 0 && sb_h > 0)
            renderer.draw_rect (sb_x,sb_y,sb_w,sb_h,fg,bg);
    }

    override
    void
    sdl_event_mouse_button_down (SDL_MouseButtonEvent* evt) {
        writeln (this);
        if (on_click)
            on_click (this, evt);
    }

    override
    void
    sdl_event_mouse_wheel (SDL_MouseWheelEvent* evt) {
        float delta_y = evt.y;
        if (evt.direction == SDL_MOUSEWHEEL_FLIPPED)
            delta_y *= -1.0f;

        float displacement = delta_y * SCROLL_SENSITIVITY;

        scroll_y += displacement.to!int;

        request_update();

        //if (delta_y > 0) {
        //    on_scroll_up (evt);
        //}
        //else 
        //if (delta_y < 0) {
        //    on_scroll_down (evt);
        //}
    }

    void
    on_scroll_up (SDL_MouseWheelEvent* evt) {
        scroll_y -= 3;
        request_update();
    }

    void
    on_scroll_down (SDL_MouseWheelEvent* evt) {
        scroll_y += 3;
        request_update();
    }
}

struct
ListViewArgs {
    bool expand = true;
    int  height = 350;
    ScrollMode scroll = ScrollMode.ALWAYS;
}

enum
ScrollMode {
    NONE,
    AUTO,
    ALWAYS,
    HIDDEN,
    ADAPTIVE,
}

struct
ListStyle {
    int padding = 3;
    int padding_x_scale = 4;
}
