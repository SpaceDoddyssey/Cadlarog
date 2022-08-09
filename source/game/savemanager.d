module savemanager;

import std.file: writeBinary = write, readBinary = read;
import vibe.data.bson;
import std.conv;

import ecsd;
import ecsd.userdata;
import game;
import levelmap;
import playermodule;
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

void saveGameInfo(){
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
    auto bson = Bson(Bson.Type.array, bytes);
    Entity ent = uni.allocEntity();
    uni.deserializeEntity(ent, bson);
    return ent;
}

void saveVerse(){
    Bson bson = uni.serialize(); // all active entities are serialized
    immutable(ubyte)[] bytes = bson.data;
    LevelMap map = uni.getUserdata!LevelMap;
    string bsonName = "savedata/Level " ~ to!string(map.levelNum) ~ ".bson";
    writeBinary(bsonName, bytes);
}

Universe loadVerse(int whichLevel){
    string bsonName = "savedata/Level " ~ to!string(whichLevel) ~ ".bson";
    auto bytes = cast(immutable(ubyte)[])readBinary(bsonName);
    auto bson = Bson(Bson.Type.array, bytes);
    Universe verse = allocUniverse();
    verse.deserialize(bson); // allocates and populates new entities
    return verse;
}