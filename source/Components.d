module components;
import dplug.math.vector;
import ecsd;
import std.stdio;
import renderer;
import events;
import std.typecons;
import std.random;

struct HP{
    int curHP, maxHP, damRed = 0;
    Entity ent = void;
    this(int h){
        curHP = maxHP = h;
    }
    void onComponentAdded(Universe verse, EntityID id){
        ent = Entity(id);
        (ent.get!PubSub).subscribe(&receiveAttack);
    }
    void takeDamage(int d){
        if (d > damRed) { curHP -= (d - damRed); } 
        if(curHP <= 0){
            (ent.get!PubSub).publish(DeathEvent());
            ent.free();
        }
        //Note: maybe should handle death better 
    }
    void receiveAttack(Entity e, ref AttackEvent a){
        int d = a.damage;
        takeDamage(d);
    }
}

struct Door{
    bool isOpen;
    string openSprite, closedSprite;
    Entity ent = void;
    void onComponentAdded(Universe verse, EntityID id){
        ent = Entity(id);
        (ent.get!PubSub).subscribe(&doorOpen);
        (ent.get!PubSub).subscribe(&doorClose);
    }
    void doorOpen(Entity e, ref OpenEvent o){
        if(!isOpen) { 
            isOpen = true; 
            (ent.get!SpriteRender).path = openSprite;
            ent.remove!TileBlock;
        } else { writeln("Door is already open!"); }
    }
    void doorClose(Entity e, ref CloseEvent c){
        if(isOpen) { 
            isOpen = false; 
            (ent.get!SpriteRender).path = closedSprite;
            ent.add!TileBlock;
        } else { writeln("Door is already closed!"); }
    }
}

struct Contents{
    Entity[] contents;
    alias contents this;
    Entity ent = void;

    void onComponentAdded(Universe verse, EntityID id){
        ent = Entity(id);
        (ent.get!PubSub).subscribe(&die);
    }
    void addContents(Entity e){
        if(e.has!SpriteRender){
            (e.get!SpriteRender()).enabled = false;
        }
        if(e.has!MapPos){
            e.remove!MapPos;
        }
        contents ~= e;
    }
    void die(Entity e, ref DeathEvent d){
        MapPos* thisPos = ent.get!MapPos;
        foreach(Entity cont ; contents){
            (cont.get!SpriteRender()).enabled = true;
            vec2i pos = thisPos.position;
            cont.add(MapPos(pos));
            publish(PlaceEntity(cont, pos));
        }
    }
}

struct Transform{ vec2i position; alias position this; }
struct MapPos{ vec2i position; alias position this; }
struct AttackBait{}
struct TileBlock{}
struct Wood{}
struct Metal{}
struct CanPickUp{}

struct Stairs{}

struct PrimaryWeaponSlot{
    Attack defaultAttack;
    Nullable!Entity equipped;
    this(Attack d){
        defaultAttack = d;
    }
    void equip(Entity w){
        if(w.has!Weapon){
            equipped = w;
        } else { writeln("Can't equip that there!"); }
    }
    void unequip(){ equipped.nullify(); }
    Attack attack(){
        if(!equipped.isNull){
            Weapon* wep = equipped.get.get!Weapon();
            return wep.attack;
        } else {
            return defaultAttack;
        }
    }
}

struct Weapon{
    Attack attack;
}

struct Attack{
    int damage;
}

struct SlimeAI{
    Dir curDir;
    Entity ent = void;
    void onComponentAdded(Universe verse, EntityID id){
        ent = Entity(id);
        curDir = cast(Dir)uniform(2, 4);
writeln("direction generated = ", cast(int)curDir);
        subscribe(&onTick);
    }
    void onTick(ref TurnTick t){
        if(ent.valid){
            publish(NpcMove(ent));
        }
    }
    void turnAround(){
        if(curDir == Dir.Up){
            curDir = Dir.Down;
        } else {
            curDir = Dir.Up;
        }
    }
}

static void registration(Universe verse){
    verse.registerBuiltinComponents;
    verse.registerComponent!Transform;
    verse.registerComponent!SpriteRender;
    verse.registerComponent!HP;
    verse.registerComponent!MapPos;
    verse.registerComponent!Door;
    verse.registerComponent!Wood;
    verse.registerComponent!Metal;
    verse.registerComponent!Contents;
    verse.registerComponent!TileBlock;
    verse.registerComponent!AttackBait;
    verse.registerComponent!Weapon;
    verse.registerComponent!Attack;
    verse.registerComponent!CanPickUp;
    verse.registerComponent!PrimaryWeaponSlot;
    verse.registerComponent!SlimeAI;
    verse.registerComponent!Stairs;
}

/*
    void onComponentAdded(Universe, EntityID)
    {
        damage = uniform(5, 25);
    }*/