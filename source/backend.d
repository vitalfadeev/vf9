module backend;

import std.stdio;
import std.file;


class
Backend {
    auto
    iter_files () {
        auto iter = Iter_files ("/home/vf/Music/vital_fadeev and SUNO");
        return iter;
    }

    struct
    Iter_files {
        string path;

        // Реализация opApply для foreach (DirEntry entry; iter)
        int 
        opApply (int delegate(ref DirEntry) dg) {
            int result = 0;

            // Перебираем элементы без рекурсии
            foreach (entry; dirEntries(path, SpanMode.shallow)) {
                // Передаем элемент в тело цикла foreach пользователя
                result = dg(entry);

                // Если пользователь вызвал break, прерываем итерацию
                if (result)
                    break;
            }

            return result;
        }
    }
}
