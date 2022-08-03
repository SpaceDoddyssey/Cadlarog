module game;

import levelmap;
import events;
import components;
import complex;
import systems;
import renderer;
import playermodule;
import entitycreation;
import guiinfo;
import randommodule;

import std.stdio;
import std.random;
import ecsd;
import ecsd.userdata;
import dplug.math.vector;
mixin registerSubscribers;

LevelMap lm;
Universe uni;

@EventSubscriber
void init(ref AppStartup s){
  rand = Random(seed);

  uni = allocUniverse();

  player = makePlayer(uni);
  lm = levelinit(uni, 50, 50);
  
  setUserdata!LevelMap(uni, lm);

  addLogMessage("Welcome to Cadlarog");
}

@EventSubscriber
void pickUp(ref PickUp p){
  MapPos* pPos = player.get!MapPos;
  Tile curTile = lm.getTile(pPos.x, pPos.y);
  Entity[] ents = curTile.entsWith!CanPickUp;
  if(ents.length > 0){
    //Obviously change this when there's more than just swords to pick up
    if(ents[0].has!Weapon){
      PrimaryWeaponSlot* pWSlot = player.get!PrimaryWeaponSlot;
      pWSlot.equip(ents[0]);
    } else if (ents[0].has!Shield){
      ShieldSlot* sSlot = player.get!ShieldSlot;
      sSlot.equip(ents[0]);
    } else {
      return;
    }
    (ents[0]).remove!MapPos;
    (ents[0].get!SpriteRender()).enabled = false;
  }
}

@EventSubscriber
void npcMove(ref NpcMove n){
  Entity ent = n.e;
  MapPos* mp = ent.get!MapPos;
  //Obviously this will change when there are other types of monsters
  SlimeAI* Sai = ent.get!SlimeAI; 
  int xDelta = 0, yDelta = 0;
  if(Sai.curDir == Dir.Left){ xDelta = -1; }
  if(Sai.curDir == Dir.Right){ xDelta = 1; }
  if(Sai.curDir == Dir.Up){ yDelta = -1; }
  if(Sai.curDir == Dir.Down){ yDelta = 1; }

  Tile target = lm.getTile(mp.x + xDelta, mp.y + yDelta);
  Entity[] blockingEnts = target.entsWith!(TileBlock)();
  if(blockingEnts.length == 0){
    if(target.type == TileType.Floor){
      vec2i source = vec2i(mp.x, mp.y);
      vec2i dest = vec2i(mp.x + xDelta, mp.y + yDelta);
      lm.moveEntity(ent, source, dest);
    } else {
      Sai.turnAround();
    }
  } else if(blockingEnts[0] != player){
    Sai.turnAround();
  } else {
    player.publish(AttackEvent(ent, player, (ent.get!PrimaryWeaponSlot).attack));
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
    vec2i source = vec2i(pMapPos.x, pMapPos.y);
    vec2i dest = vec2i(pMapPos.x + xDelta, pMapPos.y + yDelta);
    lm.moveEntity(player, source, dest);
  } else {
    if(blockingEnts.length != 0){ //Probably remove this once walls are blocking ents
      bumpInto(blockingEnts[0], player);
    }
  }
  publish(TurnTick());
}