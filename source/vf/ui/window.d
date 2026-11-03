module vf.ui.window;

import std.stdio;
import vf.std.xywh                      : Xy,Wh,Xywh;
import vf.ui.window;
import vf.ui.page;
import vf.ui.renderer;
version (SDL) import vf.sdl.importc_sdl;
version (SDL) import vf.sdl.exceptions;

class
Window {
    Wh           wh;         // ushort x ushort  16368 x 16368
    Page         page;
    SDL_Window* _sdl_window;

    this (int x, int y, int w, int h, uint flags) {
        wh.w = w;
        wh.h = h;
        _sdl_window = new_window (x,y,w,h,flags);
    }

    SDL_Window*
    new_window (int x, int y, int w, int h, uint flags) {
        // Window
        auto _sdl_window = 
            SDL_CreateWindow (
                __FILE_FULL_PATH__, // "SDL3 Window",
                w, h,
                flags
            );

        if (!_sdl_window)
            throw new SDLException ("Failed to create window");

        //SDL_SetWindowPosition (_sdl_window,x,y);

        // Update
        SDL_UpdateWindowSurface (_sdl_window);

        return _sdl_window;
    }    

    //Renderer*
    //draw_start (bool clear) {
    //    auto renderer = get_renderer ();
    //    // clear
    //    if (clear) {
    //        renderer.clear ();
    //    }
    //    return renderer;
    //}

    //void
    //draw_end (Renderer* renderer) {
    //    renderer.rasterize ();
    //    SDL_DestroyRenderer (renderer._renderer);
    //    //renderer.destroy ();
    //}

    //Renderer* 
    //get_renderer () {
    //    //1. opengl
    //    //2. opengles2
    //    //3. vulkan
    //    //4. gpu
    //    //5. software
    //    auto _sdl_renderer = SDL_CreateRenderer (_sdl_window, "opengl");
    //    //auto _sdl_renderer = SDL_CreateRenderer (_sdl_window, "software");
    //    //auto _sdl_renderer =SDL_CreateSoftwareRenderer (_sdl_window);
    //    if (_sdl_renderer is null) throw new SDLException ("SDL_CreateRenderer");
    //    return new Renderer (_sdl_renderer);
    //}    

    void
    update (Renderer renderer) {
        // wh
        // xy
        // push draw
        page.xywh.wh = wh;

        if (page)
            page.update (renderer);
    }

    void
    draw (Renderer renderer) {
        if (page)
            page.draw (renderer);

        // Rasterize
        renderer.rasterize ();
    }

    void
    do_switch (SDL_Event* evt) {
        switch (evt.type) with (SDL_EventType) {
            case SDL_EVENT_MOUSE_BUTTON_DOWN   : sdl_event_mouse_button_down  (&evt.button); break;
            case SDL_EVENT_KEY_DOWN            : sdl_event_key_down  (&evt.key); break;
            case SDL_EVENT_MOUSE_WHEEL         : sdl_event_mouse_wheel (&evt.wheel); break;
            default                            : 
        }
    }

    void
    sdl_event_mouse_button_down (SDL_MouseButtonEvent* evt) {
        with (evt) {
            auto xy = Xy (evt.x, evt.y);
            if (page)
            if (page.xywh.has (xy)) {
                page.sdl_event_mouse_button_down (evt);
            }
        }
    }

    void
    sdl_event_key_down (SDL_KeyboardEvent* evt) {
        if (evt.key == SDLK_ESCAPE) {
            SDL_Window* target_window = SDL_GetWindowFromID(evt.windowID);
            if (target_window)
                send_quit ();
        }
        if (evt.key == SDLK_Q) {
            SDL_Window* target_window = SDL_GetWindowFromID(evt.windowID);
            if (target_window)
                send_quit ();
        }
    }

    void
    sdl_event_mouse_wheel (SDL_MouseWheelEvent* evt) {
        auto xy = Xy (evt.mouse_x, evt.mouse_y);
        if (page)
        if (page.xywh.has (xy)) {
            page.sdl_event_mouse_wheel (evt);
        }
    }

    void
    send_quit () {
        SDL_Event quit_event;

        quit_event.type = SDL_EVENT_QUIT;
        quit_event.quit.timestamp = SDL_GetTicksNS(); // Необязательно, но желательно указать время в наносекундах

        // 3. Толкаем событие в очередь
        if (SDL_PushEvent(&quit_event)) {
            // Событие успешно добавлено в очередь!
            // На следующем шаге цикла SDL_PollEvent поймает его как обычно.
        } else {
            SDL_Log("Не удалось отправить событие: %s", SDL_GetError());
        }       
    }

    void
    add (Page page) {
        this.page = page;
    }
}
