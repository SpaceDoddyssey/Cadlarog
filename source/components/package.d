module components;

import ecsd;
import ecsd.events;
import dplug.math.vector;

struct Name{ string name; alias name this; }

struct Transform{ vec2i position; alias position this; }
struct MapPos{ vec2i position; alias position this; }
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
    verse.registerComponent!Name;
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