module game;

import levelmap;
import events;
import components;
import components.complex;
import components.equipslots;
import systems;
import rendermodule;
import playermodule;
import components.ai;
import entitycreation;
import guimodule;
import randommodule;
import savemanager;

import std.stdio;
import std.random;
import ecsd;
import ecsd.userdata;
import dplug.math.vector;

LevelMap lm;
Universe uni;

GameInfo gameData = void;

struct GameInfo{
  int curLevel;
  int[] savedLevels;
  float cameraX; 
  float cameraY;
  this(int i){ 
    curLevel = i; 
  }
}

void gameInit(ref AppStartup s){
  gameData = GameInfo();
  rand = Random(seed);

  uni = allocUniverse();
  player = makePlayer(uni);
  levelinit(0, uni, 50, 50);

  addLogMessage("Welcome to Cadlarog");
}

void saveGame(){
  showSavePopup();
  saveGameInfo();

  savePlayerInfo();
  player.free();
  
  saveVerse();
  player = loadPlayerInfo();
}

void loadGame(){
  showLoadPopup();
  if(player.valid){
    player.free();
  }
  uni.freeUniverse();

  loadGameInfo();
  uni = loadVerse(gameData.curLevel);

  spriteDrawables = new typeof(spriteDrawables)(lm.verse);

  player = loadPlayerInfo();

  foreach(ref Tile t; lm.tiles){
    t.ents.clear();
  }
  ComponentCache!(MapPos) mapEnts;
  mapEnts = new typeof(mapEnts)(lm.verse);
  mapEnts.refresh();
  foreach(ent, ref pos; mapEnts){
    lm.getTile(pos).add(ent);
  }
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
    target.publish(WalkedOnto());
  } else {
    if(blockingEnts.length != 0){ //Probably remove this once walls are blocking ents
      bumpInto(blockingEnts[0], player);
    }
  }
  publish(TurnTick());
}