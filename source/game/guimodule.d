module guiinfo;

import bindbc.sdl;
import bindbc.sdl.image;
import bindbc.sdl.ttf;
import std.stdio;
import std.algorithm;
import std.range;
import std.conv;
import rendermodule;
import std.string;

TTF_Font* curFont;

int fontSize = 16;
string fontPath = "fonts/PressStart2P-Regular.ttf";

TextBox[] messages;

int numMessagesToRender = 7;

SDL_Color white = { 0xFF, 0xFF, 0xFF, 0 };
SDL_Color black = { 0x00, 0x00, 0x00, 0 };
SDL_Color red   = { 0xFF, 0x00, 0x00, 0 };
SDL_Color green = { 0x00, 0xFF, 0x00, 0 };

void addLogMessage(string mess){
    messages.length++;
    messages.back = TextBox(mess);
    if(messages.length > numMessagesToRender){
        move(messages.front);
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
        SDL_Surface* surface = TTF_RenderText_Shaded(curFont, message.toStringz(), white, black);
        texture = SDL_CreateTextureFromSurface(renderer, surface);
        SDL_QueryTexture(texture, null, null, &textWidth, &textHeight);
        initialized = true;
        SDL_FreeSurface(surface);
    }
    @disable this(this);
    ~this(){
        if(texture !is null) SDL_DestroyTexture(texture);
    }
}
