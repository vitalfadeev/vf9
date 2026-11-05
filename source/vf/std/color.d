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

    this          (int r, int g, int b, int a) { this.r = r & 0xFF; this.g = g & 0xFF; this.b = b & 0xFF; this.a = a & 0xFF; }
    this          (uint b) { _a = b; }
    void opAssign (uint b) { _a = b; }
}

struct For_SDL_Color {
    ubyte r;
    ubyte g;
    ubyte b;
    ubyte a;
}
