module vf.sdl.input;

version (SDL):
import vf.sdl.importc_sdl : SDL_Init,SDL_Event,SDL_WaitEvent,SDL_RegisterEvents,Uint32;


struct
Input {
    SDL_Event front;
    bool      empty ()    { return (SDL_WaitEvent (&front) == 0); }
    void      popFront () {}

    void
    opOpAssign (string op : "~") (uint type=SDL_USEREVENT, uint code, void* data1, void* data2) {
        SDL_Event event;
        event.type       = SDL_USEREVENT;
        event.user.code  = code; 
        event.user.data1 = data1;
        event.user.data2 = data2;
        SDL_PushEvent (&event);        
    }

    void
    register_custom_events (uint n) {
        Uint32 custom_event_type = SDL_RegisterEvents (n);
        if (custom_event_type == cast (Uint32) -1) {
            // Handle error
        }
    }
}
