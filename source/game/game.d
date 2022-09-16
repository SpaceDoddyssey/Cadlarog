module game;

import components;
import components.ai;
import components.complex;
import components.equipslots;
import entitycreation;
import events;
import guimodule;
import levelmap;
import playermodule;
import randommodule;
import rendermodule;
import savemanager;
import systems;

import dplug.math.vector;
import ecsd;
import ecsd.userdata;
import std.algorithm;
import std.random;
import std.stdio;

LevelMap lm;
Universe uni;
bool takingDirInput = false;

GameInfo gameData = void;

bool rangedWeaponEquipped(){
  if(!player.has!PrimaryWeaponSlot){
    return false;
  }
  PrimaryWeaponSlot* pws = player.get!PrimaryWeaponSlot;
  if(pws.equipped.isNull){
    return false;
  }
  if(!pws.equipped.get.get!RangedWeapon){
    return false;
  }

  return(true);
}

void takeDirInput(ref DirInput input){
  vec2i delta = convertDir(input.dir);
  if(delta.x != 0 || delta.y != 0){

    RangedWeapon* rw = (player.get!PrimaryWeaponSlot).equipped.get.get!RangedWeapon;
    Entity newProjectile = uni.allocEntity();
    uni.copyEntity(rw.projectile, newProjectile);

    rangedAttack(newProjectile, player.get!MapPos().position, convertDir(input.dir));
    takingDirInput = false;
  }
  
  publish(TurnTick());
}

struct GameInfo{
  int curLevel;
  int[] savedLevels;
  float cameraX; 
  float cameraY;
  string[] messages;
  this(int i){ 
    curLevel = i; 
  }
}

void gameInit(ref AppStartup s){
  writeln("-------------------------- Game Init");
  gameData = GameInfo(0);
  levelGenRand = Random(seed);
  aiRand = Random(seed);

  uni = allocUniverse();
  player = spawnNewPlayer(uni);
  levelinit(0, uni, 50, 50);

  addLogMessage("Welcome to Cadlarog");
}

void changeLevel(int dest){
  showLoadPopup();

  savePlayerInfo();
  player.free();
  saveVerse();
  player = loadPlayerInfo();
  
  int curLevel = gameData.curLevel;
  gameData.curLevel = dest;

  if(gameData.savedLevels.canFind(dest)){
    writeln("level found");
    Universe uni2 = loadVerse(dest);
    Entity newPlayerEnt = uni2.allocEntity();
    uni.copyEntity(player, newPlayerEnt);
    player = newPlayerEnt;

    uni.freeUniverse();
    uni = uni2;

  } else {
    Universe uni2 = allocUniverse();
    Entity newPlayerEnt = uni2.allocEntity();
    uni.copyEntity(player, newPlayerEnt);
    player = newPlayerEnt;

    uni.freeUniverse();
    uni = uni2;

    levelinit(dest, uni, 50, 50);
  }

  if(curLevel < dest){
    publish(PlaceEntity(player, lm.stairsUpLoc));
    cameraXOffset = lm.stairsUpLoc.x - 15;
    cameraYOffset = lm.stairsUpLoc.y - 15;
  } else {
    publish(PlaceEntity(player, lm.stairsDownLoc));
    cameraXOffset = lm.stairsDownLoc.x - 15;
    cameraYOffset = lm.stairsDownLoc.y - 15;
  }
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
  clearLog();
  if(player.valid){
    player.free();
  }
  uni.freeUniverse();

  loadGameInfo();
  uni = loadVerse(gameData.curLevel);
  player = loadPlayerInfo();

  foreach (mess; gameData.messages){
    addLogMessage(mess);
  }
}

void pickUp(ref PickUp p){
  MapPos* pPos = player.get!MapPos;
  Tile curTile = lm.getTile(pPos.x, pPos.y);
  Entity[] ents = curTile.entsWith!CanPickUp;
  if(ents.length > 0){
    //Obviously change this when there's more than just swords to pick up
    if(ents[0].has!Weapon || ents[0].has!RangedWeapon){
      PrimaryWeaponSlot* pWSlot = player.get!PrimaryWeaponSlot;
      pWSlot.equip(ents[0]);
    } else if (ents[0].has!Shield){
      ShieldSlot* sSlot = player.get!ShieldSlot;
      sSlot.equip(ents[0]);
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

void rangedAttack(Entity projEnt, vec2i start, vec2i delta){
  TravellingProjectile* tProj = projEnt.get!TravellingProjectile;
  vec2i curPos = start;

  while(tProj.piercing >= 0){
    curPos += delta;
    Tile t = lm.getTile(curPos);

    if(t.type == TileType.Wall || t.type == TileType.RoomBorder){
      addLogMessage("Arrow hit a wall");
      break;
    }

    auto blockingEnts = t.entsWith!TileBlock;
    if(blockingEnts.length == 0){
      continue;
    } else {
      Entity target = blockingEnts[0];
      if(projEnt.has!Attack){
        Attack* a = projEnt.get!Attack;
        target.get!PubSub.publish(AttackEvent(projEnt, target, *a));
      }
      tProj.piercing--;
    }
  }
}