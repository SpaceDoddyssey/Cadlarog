module savemanager;

import std.conv;
import std.file : readBinary = read, writeBinary = write;
import vibe.data.bson;

import components;
import ecsd;
import ecsd.userdata;
import game;
import guimodule;
import levelmap;
import playermodule;
import rendermodule;

void saveGameInfo(){
    gameData.cameraX = cameraXOffset;
    gameData.cameraY = cameraYOffset;
    foreach(ref message; messages){
        gameData.messages ~= message.message;
    }
    Bson bson = serializeToBson(gameData);
    auto bytes = bson.data;
    string bsonName = "savedata/GameData.bson";
    writeBinary(bsonName, bytes);
}

void loadGameInfo(){
    string bsonName = "savedata/GameData.bson";
    auto bytes = cast(immutable(ubyte)[])readBinary(bsonName);
    auto bson = Bson(Bson.Type.object, bytes);
    gameData = deserializeBson!GameInfo(bson);
    cameraXOffset = gameData.cameraX;
    cameraYOffset = gameData.cameraY;
}

void savePlayerInfo(){
    Bson bson = uni.serializeEntity(player);
    auto bytes = bson.data;
    string bsonName = "savedata/Player.bson";
    writeBinary(bsonName, bytes);
}

Entity loadPlayerInfo(){
    string bsonName = "savedata/Player.bson";
    auto bytes = cast(immutable(ubyte)[])readBinary(bsonName);
    auto bson = Bson(Bson.Type.object, bytes);
    Entity ent = uni.allocEntity();
    uni.deserializeEntity(ent, bson);
    return ent;
}

void saveVerse(){
    Bson bson = uni.serialize(); // all active entities are serialized
    immutable(ubyte)[] bytes = bson.data;
    LevelMap map = uni.getUserdata!LevelMap;
    string bsonName = "savedata/Level" ~ to!string(map.levelNum) ~ "verse.bson";
    writeBinary(bsonName, bytes);
    
    Bson lmbson = serializeToBson(lm); // all active entities are serialized
    immutable(ubyte)[] lmbytes = lmbson.data;
    bsonName = "savedata/Level" ~ to!string(map.levelNum) ~ "lm.bson";
    writeBinary(bsonName, lmbytes);
}

Universe loadVerse(int whichLevel){
    Universe verse = allocUniverse();
    auto bsonName = "savedata/Level" ~ to!string(whichLevel) ~ "lm.bson";
    auto lmbytes = cast(immutable(ubyte)[])readBinary(bsonName);
    auto lmbson = Bson(Bson.Type.object, lmbytes);
    LevelMap newLM = deserializeBson!LevelMap(lmbson);
    lm = newLM;
    lm.verse = verse;
    setUserdata!LevelMap(verse, lm);
    bsonName = "savedata/Level" ~ to!string(whichLevel) ~ "verse.bson";
    auto bytes = cast(immutable(ubyte)[])readBinary(bsonName);
    auto bson = Bson(Bson.Type.array, bytes);
    verse.deserialize(bson); // allocates and populates new entities

    spriteDrawables = new typeof(spriteDrawables)(verse);

    foreach(ref Tile t; lm.tiles){
        t.ents.clear();
    }
    ComponentCache!(MapPos) mapEnts;
    mapEnts = new typeof(mapEnts)(verse);
    mapEnts.refresh();
    foreach(ent, ref pos; mapEnts){
        lm.getTile(pos).add(ent);
    }
    return verse;
}