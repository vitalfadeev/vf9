module vf.std.color;


struct
Color {
union {
    uint _a;  // aabbggrr
struct {
    ubyte r;
    ubyte g;
    ubyte b;
    ubyte a;
}
    For_SDL_Color sdl_color;
}

    this          (uint b) { _a = b; }
    void opAssign (uint b) { _a = b; }
}

struct For_SDL_Color {
    ubyte r;
    ubyte g;
    ubyte b;
    ubyte a;
}
