#include "window.hpp"

#include <SDL2/SDL.h>

const int FRAME_RATE = 60;

static Uint32 timer_tick(Uint32, void *pointer)
{
  Window *win = static_cast<Window *>(pointer);
  win->update();
  return 1000 / FRAME_RATE;
}


Window::Window()
  : m_win(0)
{
  if(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER) != 0)
    throw SDL_GetError();
}

Window::~Window()
{
  if(m_win)
    SDL_DestroyWindow(m_win);

  SDL_Quit();
}

#include <iostream>
void Window::start()
{
  m_win = SDL_CreateWindow("Hello World!", 100, 100, 640, 480, SDL_WINDOW_SHOWN);

  if(!m_win)
    throw SDL_GetError();

  SDL_TimerID timer = SDL_AddTimer(0, &timer_tick, this);

  while(true) {
    if(!process_events())
      break;

    SDL_Delay(42);
  }

  SDL_RemoveTimer(timer);
}

bool Window::process_events()
{
  SDL_Event e;

  while(SDL_PollEvent(&e)) {
    switch(e.type) {
    case SDL_QUIT:
      return false;
    }
  }

  return true;
}

void Window::update()
{
    std::cout << SDL_GetTicks() << std::endl;
}
