module systems;

import ecsd;
import components;
import set;
import events;
import std.stdio;
import std.experimental.logger;
//called on the contents of a tile
//when you attempt to walk into it and something blocks you
void bumpInto(Entity ent, Entity player){
    if(ent.has!AttackBait){
        ent.publish(AttackEvent(player, ent, (player.get!PrimaryWeaponSlot).attack));
        return;
    }
    if(ent.has!Door()){
        ent.publish!OpenEvent();
        return;
    }
}

void publish(Event)(Entity ent, Event ev = Event.init){
    if(ent.has!PubSub){ ent.get!PubSub.publish(ev); }
}