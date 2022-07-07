module game;

// import app;
import levelmap;
import events;
import components;

import std.stdio;
import ecsd;

Entity player = void;
LevelMap lm;
Universe uni;

shared static this(){
  subscribe(&init);
  subscribe(&loop);
  subscribe(&playerMove);
}

void init(ref AppStartup s){ 
  lm = levelinit(50, 50);
  uni = lm.verse;
    writeln("init");
}

void loop(ref LoopStruct l){
}

void playerMove(ref PlayerMove m){
  int xDelta = 0, yDelta = 0;
  if(m.dir == Dir.Left){ xDelta = -1; }
  if(m.dir == Dir.Right){ xDelta = 1; }
  if(m.dir == Dir.Up){ yDelta = 1; }
  if(m.dir == Dir.Down){ yDelta = -1; }

  MapPos pMapPos = player.get!MapPos;
  Tile target = lm.getTile(pMapPos.x + xDelta, pMapPos.y + yDelta);
  if(target.type == TileType.Floor){
    pMapPos.x += xDelta;
    pMapPos.y += yDelta;
    Transform pTransform = player.get!(Transform);
writeln("Hell0");
    pTransform.x += xDelta * 32;
    pTransform.y += yDelta * 32;
  }
}