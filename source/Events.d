module events;

import bindbc.sdl;

struct AppStartup{}
struct LoopStruct{}
struct FinishStruct{}
struct Move{ Dir dir; this(Dir d){ dir = d; } }
struct SDLEvent
{
    SDL_Event* event;
    alias event this;
}

enum Dir{
  Left,
  Right,
  Up,
  Down
}