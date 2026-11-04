import core.thread : Thread;
import core.time : msecs;
import std.stdio : writeln;
import std.string : stringToUTF8 = toStringz;

// Описание типов из оригинального mpv/client.h
extern(C) {
    struct mpv_handle;
    
    enum mpv_format {
        none = 0,
        string = 1,
        osd_string = 2,
        flag = 3,
        int64 = 4,
        double_ = 5,
        node = 6,
        node_array = 7,
        node_map = 8,
        byte_array = 9
    }

    // Сигнатуры функций библиотеки
    mpv_handle* mpv_create();
    int mpv_initialize(mpv_handle* ctx);
    void mpv_terminate_destroy(mpv_handle* ctx);
    int mpv_command(mpv_handle* ctx, const(char)** args);
    int mpv_set_option_string(mpv_handle* ctx, const(char)* name, const(char)* value);
}


struct
Mpv_backend {
    mpv_handle* mpv;

    void
    _init () {
        writeln("Инициализация библиотеки libmpv...");

        // 1. Создаем экземпляр плеера
        mpv = mpv_create();
        if (!mpv) {
            writeln("Не удалось создать контекст mpv.");
            return;
        }        
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

    void
    play_file (string video_file) {
        // 4. Загружаем файл
        writeln("Запуск воспроизведения: ", video_file);
        sendCommand(["loadfile", video_file]);

        //// 5. Демонстрация управления нативной библиотекой в цикле
        //writeln("Воспроизведение началось. Ждем 5 секунд...");
        //Thread.sleep(5000.msecs);

        //writeln("Ставим на паузу через API...");
        //sendCommand(["set", "pause", "yes"]);
        //Thread.sleep(2000.msecs);

        //writeln("Снимаем с паузы и перематываем на 30 секунд вперед...");
        //sendCommand(["set", "pause", "no"]);
        //sendCommand(["seek", "30", "relative"]);
        
        //Thread.sleep(5000.msecs);
        //writeln("Завершение работы.");        
    }
}
