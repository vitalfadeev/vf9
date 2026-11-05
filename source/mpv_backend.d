module mpv_backend;

import core.thread : Thread;
import core.time : msecs;
import std.stdio : writeln;
import std.string : stringToUTF8 = toStringz;
import std.file : thisExePath, exists;
import std.path : dirName, buildPath;

extern(C) ulong mpv_render_context_update(mpv_render_context* ctx);
enum MPV_RENDER_UPDATE_FRAME = 1;
enum MPV_EVENT_FILE_LOADED = 8;

struct mpv_handle;

extern(C) {
    struct mpv_event {
        int event_id;
        int error;
        void* data;
    }

    mpv_handle* mpv_create();
    int mpv_initialize(mpv_handle* ctx);
    void mpv_terminate_destroy(mpv_handle* ctx);
    int mpv_command(mpv_handle* ctx, const(char)** args);
    int mpv_set_option_string(mpv_handle* ctx, const(char)* name, const(char)* value);
    void mpv_set_wakeup_callback(mpv_handle* ctx, void function(void* d) cb, void* d);
    mpv_event* mpv_wait_event(mpv_handle* ctx, double timeout);
}

extern(C) {
    // ... ваши существующие объявления ...
    char* mpv_get_property_string(mpv_handle* ctx, const(char)* name);
    void mpv_free(void* data); // Для освобождения строки, полученной из mpv
}

extern(C) void on_mpv_wakeup(void* dData) {
    import vf.sdl.importc_sdl : SDL_PushEvent, SDL_Event;
    import vf.ui.ui_events : UI_EVENT_REQUEST_UPDATE;

    SDL_Event event;
    event.type = UI_EVENT_REQUEST_UPDATE;
    SDL_PushEvent(&event); 
}

// Непрозрачный тип для контекста рендеринга
struct mpv_render_context;

// Тип для функции обратного вызова обновления
alias mpv_render_update_fn = extern(C) void function(void* cb_ctx);

// Структура для передачи параметров
struct mpv_render_param {
    int type;
    void* data;
}

// Структура для инициализации OpenGL
struct mpv_opengl_init_params {
    extern(C) void* function(void* ctx, const(char)* name) get_proc_address;
    void* get_proc_address_ctx;
}

// Структура для указания целевого FBO
struct mpv_opengl_fbo {
    int fbo;
    int w;
    int h;
    int internal_format;
}

// Константы (значения взяты из render.h)
enum MPV_RENDER_PARAM_API_TYPE = 1;
enum MPV_RENDER_PARAM_OPENGL_INIT_PARAMS = 2;
enum MPV_RENDER_PARAM_OPENGL_FBO = 3;
enum MPV_RENDER_PARAM_FLIP_Y = 4;
enum MPV_RENDER_PARAM_INVALID = 0;

enum MPV_RENDER_API_TYPE_OPENGL = "opengl";

extern(C) {
    // ... ваши существующие объявления ...

    int mpv_render_context_create(mpv_render_context** res, mpv_handle* mpv, mpv_render_param* params);
    void mpv_render_context_free(mpv_render_context* ctx);
    void mpv_render_context_set_update_callback(mpv_render_context* ctx, mpv_render_update_fn callback, void* callback_ctx);
    int mpv_render_context_render(mpv_render_context* ctx, mpv_render_param* params);
}


struct Mpv_backend {
    mpv_handle* mpv;
    string current_playing_id; 
    string absoluteCoverPath;
    // В struct Mpv_backend
    mpv_render_context* renderCtx;
    mpv_opengl_fbo fboInfo; // Информация о целевом FBO
    uint fboTextureId;      // ID текстуры, в которую рендерит mpv
    uint fboId;
    int  videoWidth  = 800;
    int  videoHeight = 600;

    void _init () {
        writeln("Инициализация библиотеки libmpv...");
        mpv = mpv_create();
        if (!mpv) return;

        mpv_set_wakeup_callback(mpv, &on_mpv_wakeup, null);
    }

    void _exit() {
        writeln("Уничтожение контекста libmpv...");
        if (renderCtx) {
            mpv_render_context_free(renderCtx);
            renderCtx = null;
        }
        if (mpv) {
            mpv_terminate_destroy(mpv);
            mpv = null;
        }
    }

    void config () {
        import std.file : thisExePath, exists;
        import std.path : dirName, buildPath;
        import std.stdio : writeln;

        mpv_set_option_string(mpv, "terminal", "yes");
        mpv_set_option_string(mpv, "msg-level", "all=v");        

        mpv_set_option_string(mpv, "input-vo-keyboard", "no");
        mpv_set_option_string(mpv, "input-bindings", "MBTN_LEFT cycle pause");

        // Оконный режим и принудительное удержание окна для звука
        //mpv_set_option_string(mpv, "force-window", "yes");
        mpv_set_option_string(mpv, "audio-display", "embedded-first");
        mpv_set_option_string(mpv, "clipboard", "no");

        // Удерживаем статичные изображения на экране бесконечно
        mpv_set_option_string(mpv, "image-display-duration", "inf");

        // Оптимизация под Intel HD 2000
        mpv_set_option_string(mpv, "scale", "bilinear");
        mpv_set_option_string(mpv, "cscale", "bilinear");
        mpv_set_option_string(mpv, "dscale", "bilinear");

        // Задаём фиксированный размер окна 800x600
        //mpv_set_option_string(mpv, "geometry", "800x600");
        // Запрещаем mpv автоматически менять размер окна при смене файла
        mpv_set_option_string(mpv, "auto-window-resize", "no");
        mpv_set_option_string(mpv, "keepaspect-window", "no");

        string exeDir = dirName(thisExePath());
        absoluteCoverPath = buildPath(exeDir, "res", "nocover.png");

        if (!exists(absoluteCoverPath)) {
            absoluteCoverPath = buildPath(exeDir, "..", "res", "nocover.png");
        }

        if (exists(absoluteCoverPath)) {
            writeln("Путь к заглушке валиден: ", absoluteCoverPath);
            
            // --- ГАРАНТИРОВАННЫЙ FALLBACK ДЛЯ MPV v0.40.0 БЕЗ СКРИПТОВ ---
            // Жестко привязываем файл nocover.png как внешнюю резервную дорожку.
            // Так как "audio-display" установлен в "embedded-first", mpv обратится
            // к этой опции только в том случае, если внутри MP3 нет своего арта.
            //mpv_set_option_string(mpv, "audio-image-file", absoluteCoverPath.stringToUTF8);
            //mpv_set_option_string(mpv, "cover-art-auto-mode", "all");
        } else {
            writeln("ОШИБКА: Файл res/nocover.png не найден!");
        }

        //mpv_set_option_string(mpv, "vo", "gpu");
        // Указываем mpv, что рендеринг будет осуществляться через внешний API
        mpv_set_option_string(mpv, "vo", "libmpv");
    }

    void init_player () {
        if (mpv_initialize(mpv) < 0) {
            writeln("Ошибка инициализации mpv.");
            return;
        }        
    }

    // В struct Mpv_backend

    bool has_video_track() {
        if (!mpv) return false;
        const(char)* jsonCStr = mpv_get_property_string(mpv, "track-list");
        if (jsonCStr is null) return false;
        scope(exit) mpv_free(cast(void*)jsonCStr);

        import std.json : parseJSON, JSONType;
        import std.conv : to;

        try {
            auto json = parseJSON(jsonCStr.to!string);
            if (json.type != JSONType.array) return false;
            foreach (track; json.array) {
                if (track["type"].str == "video") return true;
            }
        } catch (Exception e) {}
        return false;
    }

    void play_file(string video_file) {
        writeln("Запуск воспроизведения: ", video_file);
        current_playing_id = video_file;
        const(char)*[] cArgs = [
            "loadfile".stringToUTF8,
            video_file.stringToUTF8,
            "replace".stringToUTF8,
            null
        ];
        mpv_command(mpv, cArgs.ptr);
    }

    void drain_events() {
        while (mpv) {
            auto event = mpv_wait_event(mpv, 0);
            if (event.event_id == 0) break; // MPV_EVENT_NONE
        }
    }

    void toggle_pause() {
        if (!mpv) return;
        writeln("Переключение воспроизведения/паузы...");
        const(char)*[] cArgs = [
            "cycle".stringToUTF8,
            "pause".stringToUTF8,
            null
        ];
        mpv_command(mpv, cArgs.ptr);
    }

    void init_render_context() {
        if (!mpv) return;

        // 1. Подготавливаем параметры инициализации OpenGL
        auto glInitParams = mpv_opengl_init_params(
            // В SDL3 эта функция может называться иначе, проверьте биндинги
            // В C это SDL_GL_GetProcAddress
            &get_proc_address_sdl,
            null
        );

        mpv_render_param[] params = [
            mpv_render_param(MPV_RENDER_PARAM_API_TYPE, cast(void*)MPV_RENDER_API_TYPE_OPENGL.ptr),
            mpv_render_param(MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, &glInitParams),
            mpv_render_param(MPV_RENDER_PARAM_INVALID, null)
        ];

        // 2. Создаем контекст рендеринга
        if (mpv_render_context_create(&renderCtx, mpv, params.ptr) < 0) {
            writeln("Не удалось создать mpv render context");
            return;
        }

        // 3. Устанавливаем колбэк, который будет вызываться, когда доступен новый кадр
        mpv_render_context_set_update_callback(renderCtx, &on_render_update, null);
    }

    // Вспомогательная функция для получения адресов GL-функций
    static
    extern(C) void* get_proc_address_sdl(void* ctx, const(char)* name) {
        import vf.sdl.importc_sdl : SDL_GL_GetProcAddress;
        return SDL_GL_GetProcAddress(name);
    }

    // Колбэк, который будет вызываться из потока mpv
    static
    extern(C) void on_render_update(void* cb_ctx) {
        // Здесь мы можем просто выставить флаг, что нужно перерисовать кадр
        // или отправить событие, как вы делали это раньше через SDL_PushEvent
        import vf.sdl.importc_sdl : SDL_PushEvent, SDL_Event;
        import vf.ui.ui_events : UI_EVENT_REQUEST_UPDATE;
        SDL_Event evt;
        evt.type = UI_EVENT_REQUEST_UPDATE;
        SDL_PushEvent(&evt);
    }

    void render_frame() {
        if (!renderCtx) return;
        if ((mpv_render_context_update(renderCtx) & MPV_RENDER_UPDATE_FRAME) == 0)
            return;

        // Указываем mpv, в какой FBO и какого размера рисовать
        fboInfo.fbo = cast(int)fboId; // ID вашего FBO
        fboInfo.w = cast(int)videoWidth; // Ширина области рендеринга
        fboInfo.h = cast(int)videoHeight; // Высота области рендеринга
        fboInfo.internal_format = 0; // Обычно 0

        int flip = 1;
        mpv_render_param[] params = [
            mpv_render_param(MPV_RENDER_PARAM_OPENGL_FBO, &fboInfo),
            mpv_render_param(MPV_RENDER_PARAM_FLIP_Y,    &flip),
            mpv_render_param(MPV_RENDER_PARAM_INVALID,   null)
        ];

        // Выполняем рендеринг
        int result = mpv_render_context_render(renderCtx, params.ptr);
        if (result < 0) {
            writeln("Ошибка рендеринга кадра mpv: ", result);
        }
    }

    void create_fbo(int w, int h, uint gl_tex) {
        import vf.sdl.importc_sdl : SDL_GL_GetProcAddress;
        import std.conv : to;

        if (gl_tex == 0) {
            writeln("create_fbo: пустой GL texture id");
            return;
        }

        alias GenFramebuffersFn    = void function(int, uint*);
        alias BindFramebufferFn    = void function(uint, uint);
        alias FramebufferTexFn     = void function(uint, uint, uint, uint, int);
        alias CheckFboStatusFn     = uint function(uint);

        auto glGenFramebuffers        = cast(GenFramebuffersFn)   SDL_GL_GetProcAddress("glGenFramebuffers");
        auto glBindFramebuffer        = cast(BindFramebufferFn)   SDL_GL_GetProcAddress("glBindFramebuffer");
        auto glFramebufferTexture2D   = cast(FramebufferTexFn)    SDL_GL_GetProcAddress("glFramebufferTexture2D");
        auto glCheckFramebufferStatus = cast(CheckFboStatusFn)    SDL_GL_GetProcAddress("glCheckFramebufferStatus");

        enum GL_TEXTURE_2D           = 0x0DE1;
        enum GL_FRAMEBUFFER          = 0x8D40;
        enum GL_COLOR_ATTACHMENT0    = 0x8CE0;
        enum GL_FRAMEBUFFER_COMPLETE = 0x8CD5;

        uint fbo;
        glGenFramebuffers(1, &fbo);
        glBindFramebuffer(GL_FRAMEBUFFER, fbo);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                               GL_TEXTURE_2D, gl_tex, 0);

        auto status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        glBindFramebuffer(GL_FRAMEBUFFER, 0);

        if (status != GL_FRAMEBUFFER_COMPLETE) {
            writeln("FBO не создан, статус: 0x", status.to!string(16));
            return;
        }

        fboId        = fbo;
        fboTextureId = gl_tex;
        videoWidth   = w;
        videoHeight  = h;
    }

    void process_events() {
        while (mpv) {
            auto ev = mpv_wait_event(mpv, 0);
            if (ev.event_id == 0) break;
            final switch (ev.event_id) {
                case MPV_EVENT_FILE_LOADED:
                    if (!has_video_track() && exists(absoluteCoverPath)) {
                        writeln("Аудио без обложки. Добавляю заглушку: ", absoluteCoverPath);
                        const(char)*[] coverArgs = [
                            "video-add".stringToUTF8,
                            absoluteCoverPath.stringToUTF8,
                            "attached-picture".stringToUTF8,
                            "no cover".stringToUTF8,
                            null
                        ];
                        mpv_command(mpv, coverArgs.ptr);
                    }
                    break;
            }
        }
    }
}

