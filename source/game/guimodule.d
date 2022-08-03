module guiinfo;

import bindbc.sdl;
import bindbc.sdl.image;
import bindbc.sdl.ttf;
import std.stdio;
import std.range;

TTF_Font* curFont;

int fontSize = 16;
string fontPath = "fonts/PressStart2P-Regular.ttf";

TextBox[] messages;

int numMessagesToRender = 7;

SDL_Color white = { 0xFF, 0xFF, 0xFF, 0 };
SDL_Color black = { 0x00, 0x00, 0x00, 0 };

void addLogMessage(string mess){
    messages ~= TextBox(mess);
    if(messages.length > numMessagesToRender){
        messages.popFront();
    }
}

struct TextBox{
    string message;
    bool initialized = false;
    int textWidth, textHeight;
    SDL_Texture * texture;
    this(string s){
        message = s;
    }
    ~this(){
        SDL_DestroyTexture(texture);
    }
}