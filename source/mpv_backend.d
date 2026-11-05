module mpv_backend;

import core.thread : Thread;
import core.time : msecs;
import std.stdio : writeln;
import std.string : stringToUTF8 = toStringz;
import std.file : thisExePath, exists;
import std.path : dirName, buildPath;

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

struct Mpv_backend {
    mpv_handle* mpv;
    string current_playing_id; 
    string absoluteCoverPath;

    void _init () {
        writeln("Инициализация библиотеки libmpv...");
        mpv = mpv_create();
        if (!mpv) return;

        mpv_set_wakeup_callback(mpv, &on_mpv_wakeup, null);
    }

    void _exit () {
        writeln("Уничтожение контекста libmpv...");
        mpv_terminate_destroy(mpv);
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
        mpv_set_option_string(mpv, "force-window", "yes");
        mpv_set_option_string(mpv, "audio-display", "embedded-first");
        mpv_set_option_string(mpv, "clipboard", "no");

        // Удерживаем статичные изображения на экране бесконечно
        mpv_set_option_string(mpv, "image-display-duration", "inf");

        // Оптимизация под Intel HD 2000
        mpv_set_option_string(mpv, "scale", "bilinear");
        mpv_set_option_string(mpv, "cscale", "bilinear");
        mpv_set_option_string(mpv, "dscale", "bilinear");

        // Задаём фиксированный размер окна 800x600
        mpv_set_option_string(mpv, "geometry", "800x600");
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

        mpv_set_option_string(mpv, "vo", "gpu");
    }

    void init_player () {
        if (mpv_initialize(mpv) < 0) {
            writeln("Ошибка инициализации mpv.");
            return;
        }        
    }

    // В struct Mpv_backend

    bool has_embedded_cover() {
        if (!mpv) return false;
        // Запрашиваем список треков в формате JSON
        const(char)* jsonCStr = mpv_get_property_string(mpv, "track-list");
        if (jsonCStr is null) return false;
        
        scope(exit) mpv_free(cast(void*)jsonCStr);
        import std.json : parseJSON, JSONValue;
        import std.conv : to;
        import std.json : parseJSON, JSONValue, JSONType;

        try {
            auto json = parseJSON(jsonCStr.to!string);
            if (json.type != JSONType.array) return false;
            
            foreach (track; json.array) {
                // Проверяем, есть ли видеотрек, помеченный как обложка (albumart)
                if (track["type"].str == "video" && 
                    track.object.get("albumart", JSONValue(false)).get!bool) {
                    return true;
                }
            }
        } catch (Exception e) {
            // В случае ошибки парсинга считаем, что обложки нет
        }
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

        // После загрузки проверяем и добавляем заглушку, если нужно
        // Небольшая задержка может потребоваться, чтобы mpv успел распарсить файл.
        // В идеале это стоит делать по событию MPV_EVENT_FILE_LOADED.
        import core.thread : Thread;
        import core.time : msecs;
        Thread.sleep(100.msecs); // Упрощённый вариант

        if (!has_embedded_cover() && exists(absoluteCoverPath)) {
            writeln("Встроенной обложки нет. Добавляю заглушку: ", absoluteCoverPath);
            const(char)*[] coverArgs = [
                "video-add".stringToUTF8,
                absoluteCoverPath.stringToUTF8,
                "attached-picture".stringToUTF8, // Флаг, помечающий трек как обложку                null
                "no cover".stringToUTF8, // title
            ];
            mpv_command(mpv, coverArgs.ptr);
        }
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
}
