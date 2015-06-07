#ifndef WINDOW_HPP
#define WINDOW_HPP

#include <string>

struct SDL_KeyboardEvent;
struct SDL_UserEvent;
struct SDL_Window;
struct SDL_WindowEvent;

class Window
{
public:
  Window(const std::string &caption);
  ~Window();

  void show();
  void redraw();
  void close();

private:
  void process_event();
  void keyboard_event(SDL_KeyboardEvent &);
  void window_event(SDL_WindowEvent &);
  void user_event(SDL_UserEvent &);

  bool is_fullscreen();
  void toggle_fullscreen();
  void update_title();

  std::string m_caption;
  SDL_Window *m_win;
  bool m_exit;
};

#endif
