#include "window.hpp"

#include <algorithm>
#include <boost/format.hpp>
#include <cairo/cairo.h>
#include <SDL2/SDL.h>

const int FRAME_RATE = 60;

static window_error make_error(const std::string &what)
{
  throw window_error(what, SDL_GetError());
}

static int event_filter(void *ptr, SDL_Event *e)
{
  // This prevent having a black window when the user is resizing the window.
  // The event filter is always called, even when SDL stops the event loop.
  if(e->window.event == SDL_WINDOWEVENT_RESIZED) {
    window *win = static_cast<window *>(ptr);
    // win->redraw();
  }

  return 1;
}

window::window(const std::string &caption)
  : m_caption(caption), m_win(0), m_exit(false)
{
  if(SDL_Init(SDL_INIT_VIDEO) != 0)
    throw make_error("SDL_Init");
}

window::~window()
{
  if(m_ren)
    SDL_DestroyRenderer(m_ren);

  if(m_win)
    SDL_DestroyWindow(m_win);

  SDL_Quit();
}

void window::show()
{
  m_win = SDL_CreateWindow("",
    SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 640, 480,
    SDL_WINDOW_RESIZABLE);

  if(!m_win)
    throw make_error("CreateWindow");


  m_ren = SDL_CreateRenderer(m_win, -1,
    SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);

  if(!m_ren)
    throw make_error("CreateRenderer");

  update_title();

  SDL_SetEventFilter(&event_filter, this);

  while(!m_exit) {
    process_events();

    if(m_set_cursor) {
      SDL_ShowCursor(!is_fullscreen());
      m_set_cursor = false;
    }

    redraw();

    SDL_Delay(1000 / FRAME_RATE);
  }
}

void window::close()
{
  m_exit = true;
}

void window::process_events()
{
  SDL_Event e;

  while(SDL_PollEvent(&e)) {
    switch(e.type) {
    case SDL_KEYDOWN:
      keyboard_event(e.key);
      break;
    case SDL_WINDOWEVENT:
      window_event(e.window);
      break;
    case SDL_QUIT:
      close();
      break;
    }
  }
}

void window::keyboard_event(SDL_KeyboardEvent &e)
{
  switch(e.keysym.sym) {
  case SDLK_q:
  case SDLK_ESCAPE:
    close();
    break;
  case SDLK_f:
    toggle_fullscreen();
    break;
  }
}

void window::window_event(SDL_WindowEvent &e)
{
  switch(e.event) {
  case SDL_WINDOWEVENT_RESIZED:
    m_set_cursor = true;
    break;
  }
}

bool window::is_fullscreen()
{
  return SDL_GetWindowFlags(m_win) & SDL_WINDOW_FULLSCREEN_DESKTOP;
}

void window::toggle_fullscreen()
{
  if(is_fullscreen())
    SDL_SetWindowFullscreen(m_win, 0);
  else
    SDL_SetWindowFullscreen(m_win, SDL_WINDOW_FULLSCREEN_DESKTOP);
}

void window::redraw()
{
  int out_w, out_h;
  SDL_GetRendererOutputSize(m_ren, &out_w, &out_h);

  SDL_Texture *tex = SDL_CreateTexture(m_ren,
    SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, out_w, out_h);

  if(!tex)
    throw make_error("CreateTexture");

  void *pixels;
  int pitch;

  if(SDL_LockTexture(tex, NULL, &pixels, &pitch) != 0)
    throw make_error("LockTexture");

  cairo_surface_t *cr_surface = cairo_image_surface_create_for_data(
    static_cast<unsigned char *>(pixels), CAIRO_FORMAT_RGB24,
    out_w, out_h, pitch);

  cairo_t *cr = cairo_create(cr_surface);

  const double zoom = std::min((double)out_w / 1080, (double)out_h / 720);
  const int real_w = 1080 * zoom;
  const int real_h = 720 * zoom;
  const int offset_x = (out_w - real_w) / 2;
  const int offset_y = (out_h - real_h) / 2;

  cairo_translate(cr, offset_x, offset_y);
  cairo_scale(cr, zoom, zoom);

  cairo_rectangle(cr, 0, 0, 1080, 720);
  cairo_clip(cr);

  // TODO: draw frames here
  cairo_set_source_rgb(cr, 1, 1, 0);
  cairo_rectangle(cr, 0, 0, 1080, 720);
  cairo_fill(cr);

  cairo_destroy(cr);
  cairo_surface_destroy(cr_surface);

  SDL_UnlockTexture(tex);

  SDL_RenderClear(m_ren);
  SDL_RenderCopy(m_ren, tex, NULL, NULL);
  SDL_RenderPresent(m_ren);

  SDL_DestroyTexture(tex);
}

void window::update_title()
{
  boost::format fmt = boost::format("%s (%d/%d) — %s")
    % "hello world" % 1 % 2 % m_caption;

  SDL_SetWindowTitle(m_win, fmt.str().c_str());
}
