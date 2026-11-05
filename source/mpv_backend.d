import core.thread : Thread;
import core.time : msecs;
import std.stdio : writeln;
import std.string : stringToUTF8 = toStringz;

struct mpv_handle;

// Описание типов из оригинального mpv/client.h
// Добавьте в блок extern(C) новые функции и типы:
extern(C) {
    // ... ваши старые объявления ...
    void mpv_set_wakeup_callback(mpv_handle* ctx, void function(void* d) cb, void* d);
    
    // Структура события для чтения состояния (опционально для расширения)
    struct mpv_event {
        int event_id;
        int error;
        void* data;
    }
    mpv_event* mpv_wait_event(mpv_handle* ctx, double timeout);
}

// С-коллбек, который mpv вызывает асинхронно при любом изменении состояния
extern(C) void on_mpv_wakeup(void* dData) {
    // Импортируем функцию отправки события SDL3 напрямую через ImportC
    import vf.sdl.importc_sdl : SDL_PushEvent, SDL_Event;
    import vf.ui.ui_events : UI_EVENT_REQUEST_UPDATE;

    SDL_Event event;
    event.type = UI_EVENT_REQUEST_UPDATE;
    SDL_PushEvent(&event); // Безопасно будит главный цикл SDL3
}

extern(C) {
    mpv_handle* mpv_create();
    int mpv_initialize(mpv_handle* ctx);
    void mpv_terminate_destroy(mpv_handle* ctx);
    int mpv_command(mpv_handle* ctx, const(char)** args);
    int mpv_set_option_string(mpv_handle* ctx, const(char)* name, const(char)* value);
    void mpv_set_wakeup_callback(mpv_handle* ctx, void function(void* d) cb, void* d);
    mpv_event* mpv_wait_event(mpv_handle* ctx, double timeout);
}


struct
Mpv_backend {
    mpv_handle* mpv;
    string current_playing_id; // Запоминаем, что сейчас играет


    void _init () {
        writeln("Инициализация библиотеки libmpv...");
        mpv = mpv_create();
        if (!mpv) return;

        // Регистрируем коллбек пробуждения
        mpv_set_wakeup_callback(mpv, &on_mpv_wakeup, null);
    }

    void
    _exit () {
        // Гарантируем уничтожение контекста при выходе из main
        writeln("Уничтожение контекста libmpv...");
        mpv_terminate_destroy(mpv);
    }
    

    void
    config () {
        // 2. Конфигурируем базовые опции перед инициализацией
        // Включаем логирование в терминал
        mpv_set_option_string(mpv, "terminal", "yes");
        mpv_set_option_string(mpv, "msg-level", "all=v");        
    }

    void
    init_player () {
        // 3. Запускаем плеер (инициализируем внутренние потоки mpv)
        if (mpv_initialize(mpv) < 0)
        {
            writeln("Ошибка инициализации mpv.");
            return;
        }        
    }

    // Helper для отправки команд в C-стиле (массив указателей, заканчивающийся null)
    void 
    sendCommand (string[] dArgs) {
        const(char)*[] cArgs;
        foreach (arg; dArgs) {
            cArgs ~= arg.stringToUTF8;
        }
        cArgs ~= null; // Обязательный маркер конца массива для Си
        mpv_command(mpv, cArgs.ptr);
    }

    void play_file (string video_file) {
        writeln("Запуск воспроизведения: ", video_file);
        current_playing_id = video_file; // Сохраняем ID трека
        sendCommand(["loadfile", video_file]);
    }

    // Метод для холостого разбора очереди событий MPV (важно, чтобы очередь не переполнялась)
    void drain_events() {
        while (mpv) {
            auto event = mpv_wait_event(mpv, 0);
            if (event.event_id == 0) break; // MPV_EVENT_NONE
            // Тут можно обрабатывать конкретные события (например, конец трека),
            // но даже просто вызов mpv_wait_event очищает внутреннюю очередь.
        }
    }
}
