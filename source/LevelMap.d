module levelmap;

import events;
import app;
import ecsd;
import ecsd.events;
import ecsd.userdata;
import rendermodule;
import entitycreation;
import perf;
import components;
import components.complex;
import playermodule;
import set;
import game;
import randommodule;

import vibe.data.serialization;
import dplug.math.vector;
import std.stdio;
import bindbc.sdl;
import bindbc.sdl.image;
import std.random;
import std.algorithm.searching;

LevelMap levelinit(int levelNum, Universe verse, int x, int y){ 
    writeln("----\nInitializing levelMap ", levelNum);
    lm = new LevelMap(levelNum, verse, x, y);
    lm.populate();
    spriteDrawables = new typeof(spriteDrawables)(lm.verse);
    return lm;
}

void placeEntity(ref PlaceEntity p){
    Entity ent = p.e;
    vec2i tilePos = p.v;
    auto level = ent.universe.getUserdata!LevelMap;
    if(auto pos = ent.tryGet!MapPos) {
        Tile t = level.getTile(pos.position);
        t.ents.remove(ent);
        pos.position = tilePos;
    } else {
        ent.add(MapPos(tilePos));
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
            initialize();
            Rect[] partitions = partitionPhase(4);
            roomGenPhase(partitions, 11);
            writeln("Connecting paths to rooms");
            foreach(Room r ; rooms){
               while(!plumbLineToPath(r)){}
               while(!plumbLineToPath(r)){}
            }
            cullDeadEnds();
            texturePhase();
        }
    ref Tile getTile(int x, int y) { return tiles[y * maxWidth + x]; }
    ref Tile getTile(vec2i pos) { return getTile(pos.v.tupleof); }
    void populate(){
        writeln("Populating entities");
        Room r = placeEntInRandomRoom("Player", null);
        placeEntInRandomRoom("crate", "sword");
        placeEntInRoom("crate", "sword", r);
        placeEntInRoom("crate", "shield", r);
        placeEntInRoom("slime_purple", null, r);
        placeEntInRoom("slime_green", null, r);
        placeEntInRandomRoom("stairs_down", null);
        if(levelNum != 0){
            placeEntInRandomRoom("stairs_up", null);
        }
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
    private Room placeEntInRandomRoom(string s, string s2){
        int whichRoom = cast(int)uniform(0, rooms.length, rand);
        Room r = rooms[whichRoom];
        int attempts = 0;
        while(attempts < 1000){
            int entX = cast(int)uniform(r.rect.mins.x+1, r.rect.maxs.x, rand);
            int entY = cast(int)uniform(r.rect.mins.y+1, r.rect.maxs.y, rand);
            Tile t = getTile(entX, entY);
            if((t.entsWith!TileBlock).length > 0){
                continue;
            } else {
                Entity pEnt = makeEntity(verse, s, s2, entX, entY);
                //writeln("Spawning entity at ", entX, " ", entY );
                getTile(entX, entY).add(pEnt);
                if(s == "Player"){
                    cameraXOffset = entX - 15;
                    cameraYOffset = entY - 15;
                }
                break;
            }
        }
        return r;
        //Expand -------------------------------
    }
    private void placeEntInRoom(string s, string s2, Room r){
        int attempts = 0;
        while(attempts < 1000){
            attempts++;
            int entX = cast(int)uniform(r.rect.mins.x+1, r.rect.maxs.x, rand);
            int entY = cast(int)uniform(r.rect.mins.y+1, r.rect.maxs.y, rand);
            Tile t = getTile(entX, entY);
            if((t.entsWith!TileBlock).length > 0){
                continue;
            } else {
                Entity pEnt = makeEntity(verse, s, s2, entX, entY);
                getTile(entX, entY).add(pEnt);
                return;
            }
        }
        writeln("Entity failed to place!");
    }
    private void initialize(){
        writeln("Populating ", maxWidth, " * ", maxHeight, " tiles");
        for(int x = 0; x < maxWidth; x++){
            for(int y = 0; y < maxHeight; y++){
                Tile T;
                T.setPos(cast(int)(x*tileSize), cast(int)(y*tileSize));
                T.mpos.x = x; T.mpos.y = y;
                T.type = TileType.Wall;
                getTile(x,y) = T;
            }
        }
    }
    private Rect[] partitionPhase(int numPartitions){
        writeln("Partitioning ", numPartitions, " times");
        Rect[] partitions;
        //The first "partition" is the entire map
        vec2i alpha = vec2i(0, 0);
        vec2i omega = vec2i(maxWidth-1, maxHeight-1);
        Rect wholeMap = Rect(alpha, omega);
        partitions ~= (wholeMap);
//writeln("Partitioning ", numPartitions, " times");
        for(int i = 0; i < numPartitions; i++){
            Rect[] newPartitions;
            if(i % 2 == 0){ //Vertical
                foreach(ref Rect space; partitions){
                    newPartitions ~= (space.partitionVertical());
                    for(int y = space.mins.y; y <= space.maxs.y; y++){
                        getTile(space.maxs.x+1,y).type = TileType.Floor;
                    }
                }
            } else { //Horizontal
                foreach(ref Rect space; partitions){
                    newPartitions ~= (space.partitionHorizontal());
                    for(int x = space.mins.x; x <= space.maxs.x; x++){
                        getTile(x,space.maxs.y+1).type = TileType.Floor;
                    }
                }
            }
            partitions ~= (newPartitions);
        } 
        return partitions;
    }
    //Takes the partitions and generates rooms in numRooms spaces. 
    //If numRooms is greater than the number of partitions, puts a room in every partition
    private void roomGenPhase(Rect[] partitions, int numRooms){
        int[] alreadyUsed;

        //writeln("roomGenPhase");
        for(int p=0; p<partitions.length; p++) {
            Rect r = partitions[p];
            //writeln("   p=", p,
            //    ", min=(", r.mins.x, ",", r.mins.y,
            //    "), max=(", r.maxs.x, ",", r.maxs.y, ")" );
        }

        for(int i = 0; i < numRooms && i < partitions.length; i++){
            int nextIndex = cast(int)uniform(0, partitions.length, rand);
            if(canFind(alreadyUsed, nextIndex)){
                i--;
                continue;
            }
            alreadyUsed ~= nextIndex;
            Rect space = partitions[nextIndex];
            int minX, minY;
            //writeln("-----\n mins.x:",space.mins.x,"  mins.y:",space.mins.y,        "\n max.x:",space.maxs.x," max.y:",space.maxs.y,        "\n minRoomWidth:",minRoomWidth," minRoomHeight:",minRoomHeight,);
            if(space.mins.x >= space.maxs.x - minRoomWidth){
                minX = cast(int)space.mins.x;
            } else {
                minX = cast(int)uniform(space.mins.x, space.maxs.x - minRoomWidth, rand);
            }           
            if(space.mins.y >= space.maxs.y - minRoomHeight){
                minY = cast(int)space.mins.y;
            } else {
                minY = cast(int)uniform(space.mins.y, space.maxs.y - minRoomHeight, rand);
            }
            vec2i botLeft = vec2i(minX, minY);

            int topX, topY;
            if(minX + minRoomWidth >= space.maxs.x){
                topX = space.maxs.x;
            } else {
                topX = cast(int)uniform(minX + minRoomWidth, space.maxs.x, rand);
            }
            if(minY + minRoomHeight >= space.maxs.y){
                topY = space.maxs.y;
            } else {
                topY = cast(int)uniform(minY + minRoomHeight, space.maxs.y, rand);
            }
            vec2i topRight = vec2i(topX, topY);

            Rect newRect = Rect(botLeft, topRight);
            rooms ~= Room(newRect);
        }
write("Placing rooms in partitions ");
foreach(int i ; alreadyUsed){ write(i, " "); }
writeln("");
        foreach(Room r; rooms){
            for(int x = r.rect.mins.x; x <= r.rect.maxs.x; x++){
                for(int y = r.rect.mins.y; y <= r.rect.maxs.y; y++){
                    //Debug.Log("(" + x + "," + y + ")");
                    if(x == r.rect.mins.x || y == r.rect.mins.y || x == r.rect.maxs.x || y == r.rect.maxs.y){
                        getTile(x, y).type = TileType.RoomBorder;
                    } else {
                        getTile(x, y).type = TileType.Floor;
                    }
                }
            }
        }
    }
    private bool plumbLineToPath(Room room){
        int side = uniform(0, 4, rand);
        int xPos, yPos; //Position of the door to be placed
        int xWalkDelta, yWalkDelta; //How much to offset each of these values (-1, 0, or 1) each step depending on what dir we're walking
        if(side <= 1){ //up-down
            xPos = uniform(room.rect.mins.x+1, room.rect.maxs.x, rand);
            xWalkDelta = 0;
            if(side == 0){ //up
                yPos = room.rect.maxs.y;
                yWalkDelta = 1;
            } else {
                yPos = room.rect.mins.y;
                yWalkDelta = -1;
            }
        } else { //left-right
            yPos = uniform(room.rect.mins.y+1, room.rect.maxs.y, rand);
            yWalkDelta = 0;
            if(side == 3){ //left
                xPos = room.rect.mins.x;
                xWalkDelta = -1;
            } else {
                xPos = room.rect.maxs.x;
                xWalkDelta = 1;
            }
        }

        int nextX = xPos;
        int nextY = yPos;
        int attempts = 0;
        while(true){
            if(attempts++ >= 100){
                writeln("Aborted! ", __FILE__, " line ", __LINE__);
                return false;
            }
            nextX += xWalkDelta;
            nextY += yWalkDelta;
            if(!(nextX < maxWidth && nextX > 0 && nextY < maxHeight && nextY > 0)){
                return false;
            } else if (getTile(nextX, nextY).type == TileType.Floor) {
                break;
            }
        }

        //If we're here, we've hit a path. Walk back and change tiles to floor.
        while(nextX != xPos || nextY != yPos){
            nextX -= xWalkDelta;
            nextY -= yWalkDelta;
            getTile(nextX, nextY).type = TileType.Floor;
        }

        //now place a door there
        Entity door = makeEntity(verse, "door", null, xPos, yPos);
        getTile(xPos, yPos).add(door);

        return true;
    }
    private void cullDeadEnds(){
        writeln("Culling dead ends");
        for(int x = 1; x < maxWidth; x++){ //First check top and bottom
            if(getTile(x, 0).type == TileType.Floor){
                int y = 0;
                while(getTile(x+1, y).type != TileType.Floor && getTile(x-1, y).type != TileType.Floor){
                    getTile(x, y).type = TileType.Wall;
                    y++;
                }
            } 
            if (getTile(x, maxHeight-1).type == TileType.Floor){
                int y = maxHeight - 1;
                while(getTile(x+1, y).type != TileType.Floor && getTile(x-1, y).type != TileType.Floor){
                    getTile(x, y).type = TileType.Wall;
                    y--;
                }
            }
        }
        for(int y = 1; y < maxHeight; y++){ //Now check left and right
            if(getTile(0, y).type == TileType.Floor){
                int x = 0;
                while(getTile(x, y+1).type != TileType.Floor && getTile(x, y-1).type != TileType.Floor){
                    getTile(x, y).type = TileType.Wall;
                    x++;
                }
            }
            if (getTile(maxWidth-1, y).type == TileType.Floor){
                int x = maxWidth - 1;
                while(getTile(x, y+1).type != TileType.Floor && getTile(x, y-1).type != TileType.Floor){
                    getTile(x, y).type = TileType.Wall;
                    x--;
                }
            }
        }
    }
    private void texturePhase(){
        foreach(t; tiles){
            string target;
            switch(t.type){
                case(TileType.Floor):
                    target = "sprites/Floor.png"; break;
                case(TileType.RoomBorder):
                    target = "sprites/RoomBorder.png"; break;
                default:
                    target = "sprites/Empty.png"; break;
            }
            t.tileEnt = makeEntity(verse, "Tile", null, t.pos.position.x, t.pos.position.y);
            t.tileEnt.add(SpriteRender(target, vec2i(32, 32), SpriteLayer.Floor));
        }
    }
}

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

enum TileType{
    Wall,
    Floor,
    RoomBorder
}

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
        int divisionPoint = uniform(leftPoint, rightPoint, rand);
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
        int divisionPoint = uniform(botPoint, topPoint, rand);
//    writeln("Horizontal partition between ", botPoint, " and ", topPoint, " at y = ", divisionPoint);

        vec2i firstTop = vec2i(maxs.x, divisionPoint - 1);

        vec2i secondOrigin = vec2i(mins.x, divisionPoint + 1);
        vec2i secondTop = maxs;
        Rect top = Rect(secondOrigin, secondTop);

        maxs = firstTop;
        return top;
    }
}

public struct Room 
{
    public Rect rect;
    public this(Rect _rect){
        rect = _rect;
    }
    alias rect this;
    //Add function to get random tile in room
}