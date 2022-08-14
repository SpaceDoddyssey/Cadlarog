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

struct NpcMove{
  Entity e;
  //vec2i v;
  this(Entity ent){
    e = ent;
    //v = vec;
  }
}

struct OpenEvent{}
struct CloseEvent{}

struct DeathEvent{}

struct TurnTick{}

struct AttackEvent{
  import components : Attack;
  Entity source, victim;
  Attack a;
  this(Entity srce, Entity vict, Attack _a){
    source = srce; victim = vict; a = _a;
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
  Entity e;
  vec2i v;
  this(Entity ent, vec2i vec){
    e = ent;
    v = vec;
  }
}