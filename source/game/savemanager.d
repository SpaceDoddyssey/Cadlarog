module savemanager;

import std.file: writeBinary = write, readBinary = read;
import vibe.data.bson;
import std.conv;

import ecsd;
import ecsd.userdata;
import game;
import levelmap;
import playermodule;

//SaveFile saveFile;

/*struct SaveFile {
    Bson savePlayer;
    LevelSave[] levels;

    public this(){
        savePlayer = uni.serializeEntity(player);
        //level stuff
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
            levelNum = map.levelNum;
            maxWidth = map.maxWidth;
            maxHeight = map.maxHeight;
            rooms = map.rooms;
        }
    }

    void addLevel(){
        
    }
}*/

void savePlayerInfo(){
    Bson bson = uni.serializeEntity(player);
    auto bytes = bson.data;
    string bsonName = "Player.bson";
    writeBinary(bsonName, bytes);
}

Entity loadPlayerInfo(){
    string bsonName = "Player.bson";
    auto bytes = cast(immutable(ubyte)[])readBinary(bsonName);
    auto bson = Bson(Bson.Type.array, bytes);
    Entity ent = uni.allocEntity();
    uni.deserializeEntity(ent, bson);
    return ent;
}

void saveVerse(){
    savePlayerInfo();
    player.free();
    Bson bson = uni.serialize(); // all active entities are serialized
    immutable(ubyte)[] bytes = bson.data;
    LevelMap map = uni.getUserdata!LevelMap;
    string bsonName = "Level " ~ to!string(map.levelNum) ~ ".bson";
    writeBinary(bsonName, bytes);
}

Universe loadVerse(int whichLevel){
    string bsonName = "Level " ~ to!string(whichLevel) ~ ".bson";
    auto bytes = cast(immutable(ubyte)[])readBinary(bsonName);
    auto bson = Bson(Bson.Type.array, bytes);
    Universe verse = allocUniverse();
    verse.deserialize(bson); // allocates and populates new entities
    return verse;
}