module game;

import levelmap;
import events;
import components;
import components.complex;
import components.equipslots;
import systems;
import renderer;
import playermodule;
import components.ai;
import entitycreation;
import guiinfo;
import randommodule;

import std.stdio;
import std.random;
import ecsd;
import ecsd.userdata;
import dplug.math.vector;

LevelMap lm;
Universe uni;

void gameInit(ref AppStartup s){
  rand = Random(seed);

  uni = allocUniverse();
  player = makePlayer(uni);
  lm = levelinit(uni, 50, 50);
  setUserdata!LevelMap(uni, lm);

  addLogMessage("Welcome to Cadlarog");
}

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
    curTile.remove(ents[0]);
  }
}

/*
void npcMove(ref NpcMove n){
  Entity ent = n.e;
  ent.poubmove();
}*/

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