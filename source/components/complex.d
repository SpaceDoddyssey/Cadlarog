module complex;

import dplug.math.vector;
import ecsd;
import ecsd.events;
import std.stdio;
import std.typecons;
import std.random;
import std.conv;
import vibe.data.serialization;

mixin registerSubscribers;

import renderer;
import events;
import guiinfo;
import playermodule;
import components;

struct HP{
    int curHP, maxHP, damRed = 0;
    @ignore
    Entity ent;
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
            Name* name = ent.get!Name;
            if(*name == "Hero"){
                addLogMessage("The Hero has fallen. All hope is lost!");
            } else {
                addLogMessage("The " ~ *name ~ " is destroyed");
            }
            (ent.get!PubSub).publish(DeathEvent());
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
    @ignore
    Entity ent;
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
    @ignore
    Entity ent;

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
            addLogMessage("The crate dropped a " ~ *(cont.get!Name()) ~ "!");
        }
    }
}

struct PrimaryWeaponSlot{
    Attack defaultAttack;
    @ignore
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

struct ShieldSlot{
    @ignore
    Entity holder;
    Nullable!Entity equipped;    
    void onComponentAdded(Universe verse, EntityID id){
        holder = Entity(id);
    }
    void equip(Entity ent){
        if(ent.has!Shield){
            equipped = ent;
            (holder.get!HP()).damRed += (ent.get!Shield()).DR;
        } else { writeln("Can't equip that there!"); }
    }
    void unequip(){ 
        (holder.get!HP()).damRed -= (equipped.get.get!Shield()).DR; 
        equipped.nullify(); 
    }
}

struct SlimeAI{
    Dir curDir;
    @ignore
    Entity ent;
    void onComponentAdded(Universe verse, EntityID id){
        ent = Entity(id);
        curDir = cast(Dir)uniform(2, 4);
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

@EventSubscriber
void registerComponents(ref UniverseAllocated ev)
{
    registerSimpleComponents(ev.universe);
    ev.universe.registerBuiltinComponents;
    ev.universe.registerComponent!SpriteRender;
    ev.universe.registerComponent!HP;
    ev.universe.registerComponent!Door;
    ev.universe.registerComponent!Contents;
    ev.universe.registerComponent!PrimaryWeaponSlot;
    ev.universe.registerComponent!ShieldSlot;
    ev.universe.registerComponent!SlimeAI;
}