module events;

import bindbc.sdl;

struct AppStartup{}
struct LoopStruct{}
struct FinishStruct{}

struct CameraMove{ Dir dir; this(Dir d){ dir = d; } }
struct PlayerMove{ Dir dir; this(Dir d){ dir = d; } }

enum Dir{
  Left,
  Right,
  Up,
  Down
}
struct SDLEvent{
    SDL_Event* event;
    alias event this;
}