module input;

import ecsd;
import events;
import bindbc.sdl;
import dplug.math.vector;

shared static this()
{
	subscribe(&processEvent);
}

private:

bool[SDL_NUM_SCANCODES] keyboardState;
bool[6] buttonState; // no _NUM_ enum :(
vec2i mousePos;

bool isKeyPressed(SDL_Keycode key, bool release = false)
{
	const scancode = SDL_GetScancodeFromKey(key);
	scope(exit) if(release) keyboardState[scancode] = false;
	return keyboardState[scancode];
}

bool isButtonPressed(ubyte button, bool release = false)
{
	assert(button > 0 && button < 6);
	scope(exit) if(release) buttonState[button] = false;
	return buttonState[button];
}

vec2i getMousePos()
{
	return mousePos;
}

void processEvent(ref SDLEvent ev)
{
	switch(ev.type)
	{
		case SDL_KEYDOWN:
		case SDL_KEYUP:
			keyboardState[ev.key.keysym.scancode] = ev.type == SDL_KEYDOWN;
			break;
		case SDL_MOUSEBUTTONDOWN:
		case SDL_MOUSEBUTTONUP:
			buttonState[ev.button.button] = ev.type == SDL_MOUSEBUTTONDOWN;
			break;
		case SDL_MOUSEMOTION:
			mousePos = vec2i(ev.motion.x, ev.motion.y);
			break;
		default:
	}
}