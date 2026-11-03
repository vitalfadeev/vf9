import std.stdio;
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
version (SDL) import vf.sdl.input       : Input;
version (SDL) import vf.sdl.importc_sdl;
version (SDL) import vf.sdl.log_event : log_event;
version (SDL) import vf.sdl.window_flags;
version (SDL) import vf.sdl.exceptions;
version (SDLTTF) import vf.sdl.fonts;
version (SDLTTF) import vf.sdl.importc_sdl_ttf;

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

	void
	run () {
		_run = true;

		INIT ();
		INIT_WINDOW ();
		INIT_RENDERER (window);
		INIT_FONTS ();

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
		page.add(
			new Row (RowArgs(
				controls           : [button3, button4, ],
			))
		);

		auto listview = new ListView (ListViewArgs(expand:true, height:350));
		foreach (a; 0..20) {
			listview.add(
				new Row (RowArgs(controls: []))
			);		    
		}

		page.add(
			new Row (RowArgs(
				controls           : [listview],
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

	void
	do_switch (SDL_Event* evt) {
	    log_event (evt);

	    switch (evt.type) with (SDL_EventType) {
	        case SDL_EVENT_QUIT 		  : this.SDL_EVENT_QUIT (&evt.quit); break;
	    	case SDL_EVENT_WINDOW_EXPOSED : window.draw (renderer); break; // event.window.windowID
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

