module vf.sdl.log_event;

import vf.sdl.importc_sdl;
import std.stdio : writefln;


void
log_event (SDL_Event* evt) {
    with (SDL_EventType)
    switch (evt.type) {
        case SDL_EVENT_MOUSE_MOTION: 
            break;
        case SDL_EVENT_MOUSE_WHEEL:
            writefln ("%s %s %+f", cast (SDL_EventType)evt.type, cast (SDL_MouseWheelDirection) evt.wheel.direction, evt.wheel.y); break;
        case SDL_EVENT_WINDOW_SHOWN                 :
        case SDL_EVENT_WINDOW_HIDDEN                :
        case SDL_EVENT_WINDOW_EXPOSED               :
        case SDL_EVENT_WINDOW_MOVED                 :
        case SDL_EVENT_WINDOW_RESIZED               :
        case SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED    :
        case SDL_EVENT_WINDOW_METAL_VIEW_RESIZED    :
        case SDL_EVENT_WINDOW_MINIMIZED             :
        case SDL_EVENT_WINDOW_MAXIMIZED             :
        case SDL_EVENT_WINDOW_RESTORED              :
        case SDL_EVENT_WINDOW_MOUSE_ENTER           :
        case SDL_EVENT_WINDOW_MOUSE_LEAVE           :
        case SDL_EVENT_WINDOW_FOCUS_GAINED          :
        case SDL_EVENT_WINDOW_FOCUS_LOST            :
        case SDL_EVENT_WINDOW_CLOSE_REQUESTED       :
        case SDL_EVENT_WINDOW_HIT_TEST              :
        case SDL_EVENT_WINDOW_ICCPROF_CHANGED       :
        case SDL_EVENT_WINDOW_DISPLAY_CHANGED       :
        case SDL_EVENT_WINDOW_DISPLAY_SCALE_CHANGED :
        case SDL_EVENT_WINDOW_SAFE_AREA_CHANGED     :
        case SDL_EVENT_WINDOW_OCCLUDED              :
        case SDL_EVENT_WINDOW_ENTER_FULLSCREEN      :
        case SDL_EVENT_WINDOW_LEAVE_FULLSCREEN      :
        case SDL_EVENT_WINDOW_DESTROYED             :
        case SDL_EVENT_WINDOW_HDR_STATE_CHANGED     :
            writefln ("%s %d", cast (SDL_EventType)evt.type, evt.window.windowID); break;
        case SDL_EVENT_KEY_DOWN:
        case SDL_EVENT_KEY_UP:
            writefln ("%s %s", cast (SDL_EventType)evt.type, evt.key.scancode); break;
        case SDL_EVENT_USER:
            writefln ("%s", cast (SDL_EventType) evt.type); break;
        default:
            writefln ("%s", cast (SDL_EventType) evt.type);
    }
}
