module vf.ui.control;

import vf.std.xywh                      : Xy,Wh,Xywh;
import vf.ui.renderer;
import vf.ui.ui_events;
version (SDL) import vf.sdl.importc_sdl;
version (SDLTTF) import vf.sdl.fonts;


class
Control {
    Xywh      xywh;
    bool      expand;
    Control   parent;
    Controls  controls;
    Wh        min_wh;
    Font      font;

    void
    set_xy (Xy xy) {
        xywh.xy = xy;
    }

    void
    update (Renderer renderer) {
        xywh.wh = min_wh;
    }

    void
    draw (Renderer renderer) {
        foreach (c; controls.norecursive) {
            c.draw (renderer);
        }
    }

    //
    void
    sdl_event_mouse_button_down (SDL_MouseButtonEvent* evt) {
        //
    }

    void
    sdl_event_mouse_wheel (SDL_MouseWheelEvent* evt) {
        //
    }
    
    auto
    recursive () {
        return Recursive (this);
    }

    import std.range;   
    struct
    Recursive {  // in deep
        Control     front;
        Control[][] childs_ranges;
        Control    _next;

        bool empty () { 
            return (front is null);
        }
        void popFront () { front = next (); }
        auto next () {
            in_deep:
            if (!front.controls.empty) {
                childs_ranges ~= front.controls.s;
                return childs_ranges.back.front;
            }

            go_right:
            if (!childs_ranges.empty) {
                if (!childs_ranges.back.empty) {
                    childs_ranges.back.popFront ();
                    if (!childs_ranges.back.empty) {
                        return childs_ranges.back.front;
                    }
                    else {
                        goto go_up;
                    }
                }
                else {
                    goto go_up;
                }
            }

            go_up:
            if (!childs_ranges.empty) {
                childs_ranges.popBack ();
                goto go_right;
            }

            end:
            return null;
        }
    }

    void
    request_update () {
        SDL_Event event;
        event.type = UI_EVENT_REQUEST_UPDATE;
        SDL_PushEvent(&event);
    }

    void 
    add (Control control) {
        controls.add (control);
    }
}


struct
Controls {
    Control[] s;

    void
    opAssign (Control[] controls) {
        foreach (c; controls) {
            s ~= c;
            //c.parent = this;
        }
    }

    void 
    add (Control control) {
        s ~= /*cast (Widget) */control;
    }

    bool empty  () { return s.length == 0; }
    auto front  () { return s[0]; }
    auto length () { return s.length; }

    auto
    norecursive () {
        return s[];
    }
}

enum
MainAxisAlignment {
    START,
}

enum
CrossAxisAlignment {
    CENTER,
}
