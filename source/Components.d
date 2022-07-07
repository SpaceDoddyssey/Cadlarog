module components;

import dplug.math.vector;

struct Transform{
    vec2i position;
    alias position this;
}

struct MapPos{
    vec2i position;
    alias position this;
}

struct HP{
    int curHP, maxHP, damRed = 0;
    this(int h){
        curHP = maxHP = h;
    }
    public void setDR(int d){ damRed = d; }
    public void takeDamage(int d){
        if (d > damRed) { curHP -= (d - damRed); } 
        //handle death - expand this in general ----------------- 
    }
}
