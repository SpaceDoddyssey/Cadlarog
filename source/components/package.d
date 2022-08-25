module components;

import ecsd;
import ecsd.events;
import ecsd.storage;
import ecsd.userdata;
import dplug.math.vector;
import vibe.data.bson;

import levelmap;

struct Name{ string name = "<unnamed>"; alias name this; }

struct Transform{ vec2i position; alias position this; }
struct MapPos{ 
    vec2i position; 
    alias position this; 
    void onComponentDeserialized(Universe uni,EntityID owner,Bson bson){
        LevelMap lm = uni.getUserdata!LevelMap;
        lm.getTile(position).add(Entity(owner));
    }
}
struct AttackBait{}
struct TileBlock{}
struct Wood{}
struct Metal{}
struct CanPickUp{}

struct Stairs{
    bool up;
    this(string s){
        if(s == "up"){ up = true; } else { up = false; }
    }
}

struct Shield{
    int DR;
}

struct Weapon{
    Attack attack;
}

struct Attack{
    int damage;
}

void registerSimpleComponents(Universe verse)
{
    verse.registerComponent!(Name, FlatStorage);
    verse.registerComponent!Transform;
    verse.registerComponent!MapPos;
    verse.registerComponent!AttackBait;
    verse.registerComponent!TileBlock;
    verse.registerComponent!Wood;
    verse.registerComponent!Metal;
    verse.registerComponent!CanPickUp;
    verse.registerComponent!Stairs;
    verse.registerComponent!Shield;
    verse.registerComponent!Weapon;
    verse.registerComponent!Attack;
}