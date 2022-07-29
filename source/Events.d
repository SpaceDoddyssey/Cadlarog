module events;

import bindbc.sdl;
import dplug.math.vector;
import ecsd;

struct AppStartup{}
struct LoopStruct{}
struct FinishStruct{}

struct CameraMove{ Dir dir; this(Dir d){ dir = d; } }
struct PlayerMove{ Dir dir; this(Dir d){ dir = d; } }
struct PickUp{}

struct OpenEvent{}
struct CloseEvent{}

struct DeathEvent{}

struct AttackEvent{
  import components : Attack;
  Attack a;
  this(Attack _a){
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

struct PlaceEntity{
  Entity e = void;
  vec2i v;
  this(Entity ent, vec2i vec){
    e = ent;
    v = vec;
  }
}