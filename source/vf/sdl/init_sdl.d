module vf.sdl.init_sdl;

import core.stdc.stdio    : printf;
import core.stdc.stdlib   : abort;
import vf.sdl.exceptions  : SDLException;
import vf.sdl.importc_sdl;

void 
init_sdl () {
    // SDL_Init (SDL_INIT_AUDIO | SDL_INIT_VIDEO | SDL_INIT_EVENTS | SDL_INIT_EVERYTHING);
    if (SDL_Init (SDL_INIT_VIDEO | SDL_INIT_EVENTS | SDL_INIT_AUDIO) < 0) {
        printf ("Failed to initialize SDL video: %s\n", SDL_GetError ());
        abort ();
    }

    // IMG
    version (SDLImage) {
        auto flags = IMG_INIT_PNG | IMG_INIT_JPG;
        if (IMG_Init (flags) != flags)
            throw new IMGException ("The SDL_Image init failed");
    }

    // TTF
    version (SDLTTF) {
        import vf.sdl.importc_sdl_ttf : TTF_Init;
        import vf.sdl.exceptions      : TTFException;
        if (TTF_Init () == -1)
            throw new TTFException ("Failed to initialise SDL_TTF");
    }

    // Mixer
    version (SDLMIXER) {
        import vf.sdl.importc_sdl_mixer;
        import vf.sdl.exceptions;

        enum SAMPLE_RATE  = 44100;
        enum AUDIO_FORMAT = 0x8010; // MIX_DEFAULT_FORMAT;  // Обычно AUDIO_S16SYS
        enum CHANNELS     = 2;
        enum CHUNK_SIZE   = 2048;

        with (MIX_InitFlags)
        if (Mix_Init (MIX_INIT_MP3 | MIX_INIT_OGG | MIX_INIT_FLAC) == -1)
            throw new SDLException ("Failed to initialise SDL_Mixer");

        // Открытие аудиоустройства
        if (Mix_OpenAudio (SAMPLE_RATE, AUDIO_FORMAT, CHANNELS, CHUNK_SIZE) < 0) {
            throw new SDLException ("Mix_OpenAudio failed");
        }

        Mix_AllocateChannels (16);
    }

    able_rendering_drivers ();
}

void
able_rendering_drivers () {
    SDL_Log ("Available renderer drivers:");

    for (int i = 0; i < SDL_GetNumRenderDrivers (); i++) {
        SDL_Log ("%d. %s", i + 1, SDL_GetRenderDriver (i));
    }

    //1. opengl
    //2. opengles2
    //3. vulkan
    //4. gpu
    //5. software    
}
