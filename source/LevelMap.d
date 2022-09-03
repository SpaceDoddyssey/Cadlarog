module levelmap;

import ecsd;
import ecsd.events;
import ecsd.userdata;

import app;
import components;
import components.complex;
import entitycreation;
import events;
import game;
import levelgen;
import perf;
import playermodule;
import randommodule;
import rendermodule;
import set;

import bindbc.sdl;
import bindbc.sdl.image;
import dplug.math.vector;
import std.algorithm.searching;
import std.random;
import std.stdio;
import vibe.data.serialization;

import components.traps;

LevelMap levelinit(int levelNum, Universe verse, int x, int y){ 
    writeln("Initializing levelMap ", levelNum);
    lm = new LevelMap(levelNum, verse, x, y);
    populate();
    writeln("----------");
    spriteDrawables = new typeof(spriteDrawables)(lm.verse);
    return lm;
}

void placeEntity(ref PlaceEntity p){
    Entity ent = p.e;
    vec2i tilePos = p.v;
    auto level = ent.universe.getUserdata!LevelMap;
    
    if(auto pos = ent.tryGet!MapPos){
        Tile t = level.getTile(pos.position);
        t.ents.remove(ent);
        pos.position = tilePos;
    } else {
        ent.add(MapPos(tilePos));
    }

    if(auto pos = ent.tryGet!Transform){
        pos.position = vec2i(tilePos.x*32, tilePos.y*32);
    } else {
        ent.add(Transform(vec2i(tilePos.x*32, tilePos.y*32)));
    }
    level.getTile(tilePos).ents.add(ent);
}

class LevelMap{
    public:
        int levelNum;
        @ignore
        Universe verse;
        static float tileSize = 1.0f;
        int maxWidth, maxHeight;
        @ignore
        int minRoomWidth = 5, minRoomHeight = 5;
        @ignore
        int maxRoomWidth = 8, maxRoomHeight = 8;
        vec2i stairsUpLoc, stairsDownLoc;
        Tile[] tiles;
        Room[] rooms;
        this() @safe {}
        this(int which, Universe uni, int _x, int _y){
            levelNum = which;
            verse = uni;
            setUserdata!LevelMap(verse, this);
            gameData.savedLevels ~= which;

            maxWidth = _x;
            maxHeight = _y;
            tiles = new Tile[_x * _y];

            initialize(this);
            Rect[] partitions = partitionPhase(this, 4);
            roomGenPhase(this, partitions, 11);
            writeln("Connecting paths to rooms");
            foreach(Room r ; rooms){
               while(!plumbLineToPath(this, r)){}
               while(!plumbLineToPath(this, r)){}
            }
            cullDeadEnds(this);
            texturePhase(this);
        }
    ref Tile getTile(int x, int y) { return tiles[y * maxWidth + x]; }
    ref Tile getTile(vec2i pos) { return getTile(pos.v.tupleof); }
    ref Room getRandomRoom(){
        int whichRoom = cast(int)uniform(0, rooms.length, levelGenRand);
        return rooms[whichRoom];
    }
    void lookForEnts(){ //debug function
        foreach(Tile t ; tiles){
            if(t.ents.length() != 0){
                writeln("Ent(s) found at ", t.mpos.x, " ", t.mpos.y);
            }
        } writeln("done looking");
    }
    void moveEntity(Entity e, vec2i source, vec2i dest){
        if(e.has!MapPos){
            MapPos* m = e.get!MapPos;
            m.position = dest;
        }
        if(e.has!Transform){
            Transform* t = e.get!Transform;
            t.position = vec2i(dest.x * 32, dest.y * 32);
        }

        getTile(source).remove(e);
        getTile(dest).add(e);
    }
    Entity placeEntInRoom(string s1, string s2, Room r){
        Entity ent = makeEntity(verse, s1, s2);
        placeEntInRoom(ent, r);
        return ent;
    }
    void placeEntInRoom(Entity ent, Room r){
        int attempts = 0;
        while(attempts < 1000){
            attempts++;
            vec2i randVec = r.randPointIn();
            Tile t = getTile(randVec);
            if((t.entsWith!TileBlock).length > 0){
                continue;
            } else {
                publish(PlaceEntity(ent, randVec));
                getTile(randVec).add(ent);
                return;
            }
        }
        writeln("Entity failed to place!");
    }
    void placeArrowTrap(Entity prPlate, Entity trap, vec2i loc){
        import std.algorithm: canFind;
        //Place the plate
        publish(PlaceEntity(prPlate, loc));
        (prPlate.get!PressurePlate()).trapToTrigger = trap;
        //crawl in random direction, if you hit a door try a different direction
        int[] alreadyChecked;
        vec2i walkDelta;
        while(alreadyChecked.length < 4){
            int dir = uniform(0, 4, levelGenRand);
            if(canFind(alreadyChecked, dir)){
                continue;
            }
            alreadyChecked ~= dir;
            if(dir <= 1){ //up-down
                walkDelta.x = 0;
                //if up else down
                if(dir == 0){ walkDelta.y = 1; } else { walkDelta.y = -1; }
            } else { //left-right
                walkDelta.y = 0;
                //if left else right
                if(dir == 3){ walkDelta.x = -1; } else { walkDelta.x = 1; }
            }
            bool wall = false;
            vec2i checkPos = loc;
            while(true){
                checkPos += walkDelta;
                Tile t = getTile(checkPos);
                if(t.type == TileType.RoomBorder){
                    publish(PlaceEntity(trap, checkPos));
                    return;
                } else if ((t.entsWith!Door()).length > 0){
                    break;
                }
            }
        }
        //if you hit a wall place the trap there
        //tell it to face the direction you crawled from
    }
}
//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
public struct Tile{
    Transform pos;
    MapPos mpos;
    TileType type;
    @ignore
    SDL_Texture* tex;
    @ignore
    Entity tileEnt;
    void setPos(int x, int y){
        pos.position.x = x;
        pos.position.y = y;
    }
    Set!Entity ents;
    Entity[] entsWith(Component)(){
        Entity[] result;
        Entity[] invalids;
        foreach(Entity ent ; ents){
            if(!ent.valid){ invalids ~= ent; continue; }
            if(ent.has!Component){
                result ~= ent;
            }
        }
        foreach(Entity inv ; invalids){
            ents.remove(inv);
            //Worried about this not happening if I access things through other methods
        }
        return result;
    }
    void publish(T)(T event) {//if(__traits(compiles, { ent.publish!T; })) {
        foreach(Entity ent; entsWith!PubSub()){
            ent.publish(event);
        }
    }
    void add(Entity ent){ ents.add(ent); }
    void remove(Entity ent){ ents.remove(ent); }
}
//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
enum TileType{
    Wall,
    Floor,
    RoomBorder
}
//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
public struct Rect
{
    public vec2i mins, maxs;
    public this(vec2i botLeft, vec2i topRight){
        mins = botLeft;
        maxs = topRight;
    }
    public int width(){
        return (maxs.x - mins.x);
    }
    public int height(){
        return (maxs.y - mins.y);
    }
    //Cuts the rectangle in half with a one-block-thick vertical slice, making this Rect the left-hand rectangle and returning the right-hand rectangle
    public Rect partitionVertical(){    
        int leftPoint = mins.x + width()/3;
        int rightPoint = maxs.x - width()/3;
        int divisionPoint = uniform(leftPoint, rightPoint, levelGenRand);
//    writeln("Vertical partition between ", leftPoint, " and ", rightPoint, " at x = ", divisionPoint);
    
        vec2i firstTop = vec2i(divisionPoint - 1, maxs.y);

        vec2i secondOrigin = vec2i(divisionPoint + 1, mins.y);
        vec2i secondTop = maxs;
        Rect right = Rect(secondOrigin, secondTop);

        maxs = firstTop;
        return right;
    }
    //Cuts the rectangle in half with a one-block-thick horizontal slice, making this Rect the bottom rectangle and returning the top rectangle
    public Rect partitionHorizontal(){    
        int botPoint = mins.y + height()/3;
        int topPoint = maxs.y - height()/3;
        int divisionPoint = uniform(botPoint, topPoint, levelGenRand);
//    writeln("Horizontal partition between ", botPoint, " and ", topPoint, " at y = ", divisionPoint);

        vec2i firstTop = vec2i(maxs.x, divisionPoint - 1);

        vec2i secondOrigin = vec2i(mins.x, divisionPoint + 1);
        vec2i secondTop = maxs;
        Rect top = Rect(secondOrigin, secondTop);

        maxs = firstTop;
        return top;
    }
    public vec2i randPointIn(){
        int resultX = cast(int)uniform(mins.x+1, maxs.x, levelGenRand);
        int resultY = cast(int)uniform(mins.y+1, maxs.y, levelGenRand);
        return vec2i(resultX, resultY);
    }
    public vec2i randPointOnBorder(){ //Excludes corners
        int dir = uniform(0, 4, levelGenRand);
        int xPos, yPos;
        if(dir <= 1){ //up-down
            xPos = uniform(mins.x+1, maxs.x, levelGenRand);
            if(dir == 0){
                yPos = maxs.y;
            } else {
                yPos = mins.y;
            }
        } else { //left-right
            yPos = uniform(mins.y+1, maxs.y, levelGenRand);
            if(dir == 2){
                xPos = maxs.x;
            } else {
                xPos = mins.x;
            }
        }
        return vec2i(xPos, yPos);
    }
}
//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
public struct Room 
{
    public Rect rect;
    public this(Rect _rect){
        rect = _rect;
    }
    alias rect this;
    //Add function to get random tile in room
}