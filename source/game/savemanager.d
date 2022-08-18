module savemanager;

import std.file: writeBinary = write, readBinary = read;
import vibe.data.bson;
import std.conv;

import ecsd;
import ecsd.userdata;
import game;
import levelmap;
import rendermodule;
import playermodule;

void saveGameInfo(){
    gameData.cameraX = cameraXOffset;
    gameData.cameraY = cameraYOffset;
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
    string bsonName = "savedata/Level " ~ to!string(map.levelNum) ~ "verse.bson";
    writeBinary(bsonName, bytes);
    
    Bson lmbson = serializeToBson(lm); // all active entities are serialized
    immutable(ubyte)[] lmbytes = lmbson.data;
    bsonName = "savedata/Level " ~ to!string(map.levelNum) ~ "lm.bson";
    writeBinary(bsonName, lmbytes);
}

Universe loadVerse(int whichLevel){
    Universe verse = allocUniverse();
    auto bsonName = "savedata/Level " ~ to!string(whichLevel) ~ "lm.bson";
    auto lmbytes = cast(immutable(ubyte)[])readBinary(bsonName);
    auto lmbson = Bson(Bson.Type.object, lmbytes);
    LevelMap newLM = deserializeBson!LevelMap(lmbson);
    lm = newLM;
    lm.verse = verse;
    setUserdata!LevelMap(verse, lm);
    bsonName = "savedata/Level " ~ to!string(whichLevel) ~ "verse.bson";
    auto bytes = cast(immutable(ubyte)[])readBinary(bsonName);
    auto bson = Bson(Bson.Type.array, bytes);
    verse.deserialize(bson); // allocates and populates new entities
    return verse;
}

/*
SaveFile saveFile = void;

public struct SaveFile {
    Bson savePlayer;
    LevelSave[] levels;

    public void save(){
        savePlayerInfo();
        player.free();
        Bson bson = uni.serialize(); // all active entities are serialized
        immutable(ubyte)[] bytes = bson.data;
        LevelMap map = uni.getUserdata!LevelMap;
        string bsonName = "Level " ~ to!string(map.levelNum) ~ ".bson";
        writeBinary(bsonName, bytes);
    }

    static struct LevelSave {
        Bson universe;
        uint[] tiles;
        int levelNum;
        int maxWidth, maxHeight;
        int minRoomWidth = 5, minRoomHeight = 5;
        int maxRoomWidth = 8, maxRoomHeight = 8;
        Room[] rooms;
        this(LevelMap map){
            universe = uni.serialize();
            levelNum = map.levelNum;
            maxWidth = map.maxWidth;
            maxHeight = map.maxHeight;
            rooms = map.rooms;
        }
    }

    void addLevel(){
        
    }
}
*/
