import std.stdio;
import std.path : baseName; // Нужен для очистки пути
import vf.std.xywh                      : Xy,Wh,Xywh;
import vf.std.color        : Color;
import vf.ui.control;
import vf.ui.listview;
import vf.ui.row;
import vf.ui.renderer;
import vf.ui.window;
import vf.ui.page;
import vf.ui.button;
import vf.ui.label;
import vf.ui.ui_events;
version (SDL) import vf.sdl.input       : Input;
version (SDL) import vf.sdl.importc_sdl;
version (SDL) import vf.sdl.log_event : log_event;
version (SDL) import vf.sdl.window_flags;
version (SDL) import vf.sdl.exceptions;
version (SDLTTF) import vf.sdl.fonts;
version (SDLTTF) import vf.sdl.importc_sdl_ttf;
import backend;
import mpv_backend : Mpv_backend;

void 
main () {
	writeln ("Edit source/app.d to start your project.");
	new App().run ();
}

class
App {
	Input  input;
	bool   _run;
	Window   window;
	Renderer renderer;
	Mpv_backend mpv_backend;
	ListView listview; // Выносим в поля класса для доступа из do_switch

	void
	run () {
		_run = true;

		INIT ();
		INIT_WINDOW ();
		INIT_RENDERER (window);
		INIT_FONTS ();
		mpv_backend._init ();
		scope(exit) {
			mpv_backend._exit ();
		}
		mpv_backend.config ();
		mpv_backend.init_player ();

		auto page = new Page ();
		window.add (page);

		auto button1 = new Button ("Text 1");
		auto button2 = new Button ("Text 2");
		page.add(
			new Row (RowArgs(
				controls           : [button1, button2, ],
			))
		);

		auto button3 = new Button ("Text 3");
		auto button4 = new Button ("Text 4");
		auto button5 = new Button ("Text 5");
		page.add(
			new Row (RowArgs(
				controls           : [button3, button4, button5, ],
			))
		);

		listview = new ListView (ListViewArgs(expand:true, height:350));
		auto back_end = new Backend ();
		
		foreach (entry; back_end.iter_files()) {
		    auto row = new Row (RowArgs(controls: [new Label (baseName(entry.name), fonts.s[5])]));
		    row.id = entry.name;
		    row.style.fixed_wh.h = 48;
		    row.style.padding = 11;
		    row.style.padding_x = 22;
		    
		    row.on_click = (clickedRow, evt) {
		        mpv_backend.play_file(clickedRow.id);
		        // Принудительно генерируем событие обновления, чтобы сразу перерисовать UI
		        import vf.sdl.importc_sdl : SDL_Event, SDL_PushEvent;
		        SDL_Event uEvt; uEvt.type = UI_EVENT_REQUEST_UPDATE; SDL_PushEvent(&uEvt);
		    };
		    listview.add(row);            
		}

		page.add(
			new Row (RowArgs(
				controls           : [listview],
			),
			RowStyle (
				fixed_wh: Wh(0,350)
			))
		);

		button1.on_click = (button, evt) {
			writeln (button, " ", *evt);
		};
		
		window.update(renderer);

	    foreach (ref evt; input) {
	    	do_switch (&evt);
	    	if (!_run) break;
	    }
	}

	void do_switch (SDL_Event* evt) {
	    log_event (evt);

	    switch (evt.type) with (SDL_EventType) {
	        case SDL_EVENT_QUIT: 
	            this.SDL_EVENT_QUIT (&evt.quit); 
	            break;
	            
	        case SDL_EVENT_WINDOW_EXPOSED: 
	            window.draw (renderer); 
	            break;
	            
	        case UI_EVENT_REQUEST_UPDATE: 
	            // 1. Очищаем очередь событий mpv в контексте главного потока
	            mpv_backend.drain_events(); 
	            
	            // 2. Логика подсветки активного трека
	            if (listview) {
	                foreach (control; listview.controls.norecursive) { // Предполагается, что у ListView есть доступ к дочерним элементам
	                    if (auto row = cast(Row)control) {
	                        if (row.id == mpv_backend.current_playing_id) {
	                            // Подсвечиваем активный (например, серым/синим цветом)
	                            row.style.bg = Color(40, 120, 200, 255); 
	                        } else {
	                            // Сбрасываем цвет для остальных (например, прозрачный или дефолтный)
	                            row.style.bg = Color(0, 0, 0, 0); 
	                        }
	                    }
	                }
	            }
	            
	            window.update(renderer); 
	            window.draw (renderer); 
	            break;

	        //case MPV_EVENT_FILE_LOADED:
	        //    // Файл полностью загружен, можно проверять обложку
	        //    // Здесь вызывайте логику добавления заглушки
	        //    break;
	                	            
	        default: 
	    }

	    if (window) 
	        window.do_switch (evt);
	}

	void
	INIT () {
	    import vf.sdl.init_sdl : init_sdl;
	    init_sdl ();
	}

	void
	INIT_WINDOW () {
		window = new Window (
			0,0, 800,600, 
			SDL_WINDOW_RESIZABLE
			//| SDL_WINDOW_OPENGL
			//SDL_WINDOW_BORDERLESS
			//| SDL_WINDOW_ALWAYS_ON_TOP
			//| SDL_WINDOW_UTILITY
			//| SDL_WINDOW_OPENGL
			// | SDL_WINDOW_VULKAN
			// | SDL_WINDOW_ALLOW_HIGHDPI
		);
	}

	void
	INIT_RENDERER (Window window) {
		renderer = new Renderer (window);
	}

	void
	INIT_FONTS () {
		_init_fonts ();
	}

	void
	SDL_EVENT_QUIT (SDL_QuitEvent* evt) {
	    _run = false;
	}
}

