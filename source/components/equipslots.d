module components.equipslots;

import components;

import ecsd;
import vibe.data.serialization;
import std.stdio;
import std.typecons;

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
            holder.get!DR().dr += (ent.get!Shield()).DR;
        } else { writeln("Can't equip that there!"); }
    }
    void unequip(){ 
        holder.get!DR().dr -= (equipped.get.get!Shield()).DR; 
        equipped.nullify(); 
    }
}

struct DR{
    int dr;
    alias dr this;
}

void registerEquipComponents(Universe verse)
{
    verse.registerComponent!PrimaryWeaponSlot;
    verse.registerComponent!ShieldSlot;
    verse.registerComponent!DR;
}