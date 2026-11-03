module vf.sdl.fontconfig;

import vf.sdl.importc_fontconfig;
import std.stdio  : writeln;
import std.string : toStringz;
import std.string : fromStringz;
import std.conv   : to;


struct
Fontconfig {
    void
    _init () {
        if (!FcInit ()) {
            writeln ("Не удалось инициализировать Fontconfig");
        }
    }

    ~this() {
        FcFini();        
    }

    string
    select (string font_name) {  // "NotoSansMNerd-Regular-64"
        // 3. Создание паттерна для поиска (например, Noto)
        FcPattern* pat = FcNameParse (cast(const(FcChar8)*) font_name.toStringz);
        scope (exit) FcPatternDestroy (pat);

        // 4. Подстановка стандартных значений и конфигурации
        FcConfigSubstitute (null, pat, FcMatchPattern);
        FcDefaultSubstitute (pat);

        // 5. Поиск наилучшего соответствия
         FcResult result;
         FcPattern* match = FcFontMatch (null, pat, &result);
         if (!match) {
             writeln ("Шрифт не найден");
             return "";
         }
         scope (exit) FcPatternDestroy (match);

         // 6. Извлечение пути к файлу
         FcChar8* file;
         if (FcPatternGetString (match, cast (char*) FC_FILE, 0, &file) == FcResultMatch) {
             // Преобразование из C-строки (FcChar8*) в строку D
             string filePath = fromStringz (cast(char*)file).to!string;
             writeln ("Найден файл шрифта: ", filePath);
             return filePath;
         } else {
             writeln ("Не удалось получить путь к файлу");
         }

         return "";
    }
}

