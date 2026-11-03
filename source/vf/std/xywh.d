module vf.std.xywh;

struct
Xy {
union {
    ushort a;
struct {
    uint x;
    uint y;
}
}
    this (uint x, uint y) {
        this.x = x;
        this.y = y;
    }
    this (float x, float y) {
        import std.conv;
        import std.math;
        this.x = x.round.to!uint;
        this.y = y.round.to!uint;
    }
}

struct
Wh {
union {
    ushort a;
struct {
    uint w;
    uint h;
}
struct {
    uint x;
    uint y;
}
}
    void opAssign (uint b) { a = b &0xFFFF; }
}

struct
Xywh {
union {
    uint a;
struct {
    Xy xy;
    Wh wh;
}
struct {
    uint x;
    uint y;
    uint w;
    uint h;
}
}

    bool
    has (Xy xy) {
        if (this.x <= xy.x)
        if (this.y <= xy.y)
        if (xy.x < this.x + this.w)
        if (xy.y < this.y + this.h)
            return true;
        return false;
    }

    string
    toString () {
        import std.format;
        return format!"Xywh(%3d,%3d %3d x%3d)" (x,y,w,h);
    }
}
