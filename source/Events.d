module events;

import bindbc.sdl;

struct AppStartup{}
struct LoopStruct{}
struct FinishStruct{}

struct CameraMove{ Dir dir; this(Dir d){ dir = d; } }
struct PlayerMove{ Dir dir; this(Dir d){ dir = d; } }

struct OpenEvent{}
struct CloseEvent{}

struct DeathEvent{}

struct AttackEvent{
  import components : Attack;
  Attack* a;
  this(Attack* _a){
    a = _a;
  }
  alias a this;
}

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