module components.complex;

import dplug.math.vector;
import ecsd;
import ecsd.events;
import std.conv;
import std.random;
import std.stdio;
import std.typecons;
import vibe.data.bson;
import vibe.data.serialization;

import rendermodule;
import events;
import guimodule;
import playermodule;
import components;

struct TravellingProjectile{
    Entity ent;
    int piercing;
    int damage;
    void onComponentAdded(Universe verse, EntityID id){
        ent = Entity(id);
    }
    this(int p, int d){
        piercing = p;
        damage = d;
    }
}

struct HP{
    int curHP, maxHP, damRed = 0;
    Entity ent;
    this(int h){
        curHP = maxHP = h;
    }
    void onEntitySpawned(Universe uni,EntityID owner){
        ent.subscribe(&receiveAttack);
    }
    void onComponentAdded(Universe verse, EntityID id){
        ent = Entity(id);
    }
    void takeDamage(int d){
        if (d > damRed) { curHP -= (d - damRed); } 
        if(curHP <= 0){
            Name* name = ent.get!Name;
            if(*name == "Hero"){
                addLogMessage("The Hero has fallen. All hope is lost!");
            } else {
                addLogMessage("The " ~ *name ~ " is destroyed");
            }
            ent.publish(DeathEvent());
            ent.free();
        }
        //Note: maybe should handle death better 
    }
    void receiveAttack(Entity e, ref AttackEvent atEv){
        int damageDone = atEv.a.damage - damRed;
        if(damageDone < 0) { damageDone = 0; }
        if(atEv.source == player){
            string s = "You deal " ~ to!string(damageDone) ~ " damage to the " ~ *(atEv.victim.get!Name);
            addLogMessage(s);
        } else if (atEv.victim == player){
            string s = "The " ~ *(atEv.source.get!Name) ~ " deals " ~ to!string(damageDone) ~ " damage to you!";
            addLogMessage(s);
        }
        int d = atEv.damage;
        takeDamage(d);
    }
}

struct Door{
    bool isOpen;
    string openSprite, closedSprite;
    Entity ent;
    void onEntitySpawned(Universe uni, EntityID owner){
        ent.subscribe(&doorOpen);
        ent.subscribe(&doorClose);
    }
    void onComponentAdded(Universe verse, EntityID id){
        ent = Entity(id);
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
    Entity ent; //the entity for the crate itself
    void onEntitySpawned(Universe uni,EntityID owner){
        ent.subscribe(&die);
    }
    void onComponentAdded(Universe verse, EntityID id){
        ent = Entity(id);
    }
    void addContents(Entity e){
        if(e.has!SpriteRender){
            (e.get!SpriteRender()).enabled = false;
        }
        /*if(e.has!MapPos){
            writeln("stripping item of mapPos component");
            e.remove!MapPos;
        }*/
        contents ~= e;
    }
    void die(Entity e, ref DeathEvent d){
        if(contents.length > 0 && !contents[0].valid) return;
        MapPos* thisPos = ent.get!MapPos;
        foreach(Entity cont ; contents){
            (cont.get!SpriteRender()).enabled = true;
            vec2i pos = thisPos.position;
            //cont.add(MapPos(pos));
            publish(PlaceEntity(cont, pos));
            addLogMessage("The crate dropped a " ~ *(cont.get!Name()) ~ "!");
        }
    }
}

void registerComplexComponents(Universe verse)
{
    verse.registerComponent!TravellingProjectile;
    verse.registerComponent!SpriteRender;
    verse.registerComponent!HP;
    verse.registerComponent!Door;
    verse.registerComponent!Contents;
}