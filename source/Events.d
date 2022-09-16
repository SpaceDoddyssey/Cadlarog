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

struct WalkedOnto{}
struct Trigger{}

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

vec2i convertDir(Dir direc){
  if(direc == Dir.Up){ return vec2i(0, -1); }
  if(direc == Dir.Down){ return vec2i(0, 1); }
  if(direc == Dir.Left){ return vec2i(-1, 0); }
  if(direc == Dir.Right){ return vec2i(1, 0); }
  else { return vec2i(0, 0); }
}

struct DirInput{
  Dir dir;
  this(Dir d){
    dir = d;
  }
}

enum Dir{
  None,
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