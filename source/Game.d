module game;

// import app;
import levelmap;
import events;
import components;
import systems;
import renderer;

import std.stdio;
import ecsd;
mixin registerSubscribers;

Entity player = void;
LevelMap lm;
Universe uni;

@EventSubscriber
void init(ref AppStartup s){ 
  lm = levelinit(50, 50);
  uni = lm.verse;
    writeln("init");
  //lm.lookForEnts();
}

@EventSubscriber
void pickUp(ref PickUp p){
  MapPos* pPos = player.get!MapPos;
  Tile curTile = lm.getTile(pPos.x, pPos.y);
  Entity[] ents = curTile.entsWith!CanPickUp;
  writeln(__LINE__);
  if(ents.length > 0){
    //Obviously change this when there's more than just swords to pick up
    PrimaryWeaponSlot* pWSlot = player.get!PrimaryWeaponSlot;
    (ents[0]).remove!MapPos;
    (ents[0].get!SpriteRender()).enabled = false;
    pWSlot.equip(ents[0]);
    writeln(__LINE__);
  }
}

@EventSubscriber
void playerMove(ref PlayerMove m){
  int xDelta = 0, yDelta = 0;
  if(m.dir == Dir.Left){ xDelta = -1; }
  if(m.dir == Dir.Right){ xDelta = 1; }
  if(m.dir == Dir.Up){ yDelta = -1; }
  if(m.dir == Dir.Down){ yDelta = 1; }

  MapPos* pMapPos = player.get!MapPos;
  Tile target = lm.getTile(pMapPos.x + xDelta, pMapPos.y + yDelta);
  Entity[] blockingEnts = target.entsWith!(TileBlock)();
  if(target.type == TileType.Floor && blockingEnts.length == 0){
    int originalX = pMapPos.x;
    int originalY = pMapPos.y;
    pMapPos.x += xDelta;
    pMapPos.y += yDelta;
    Transform* pTransform = player.get!Transform;

    pTransform.x += xDelta * 32;
    pTransform.y += yDelta * 32;

    lm.getTile(originalX, originalY).remove(player);
    lm.getTile(pMapPos.x, pMapPos.y).add(player);
  //writeln(">", pTransform.x, " ", pTransform.y);
  //writeln(pMapPos.x, " ", pMapPos.y);
  } else {
    if(blockingEnts.length != 0){ //Probably remove this once walls are blocking ents
      bumpInto(blockingEnts[0], player);
    }
  }
}
