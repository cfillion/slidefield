#ifndef WINDOW_HPP
#define WINDOW_HPP

struct SDL_Window;

class Window
{
public:
  Window();
  ~Window();

  void start();
  void update();

private:
  bool process_events();

  SDL_Window *m_win;
};

#endif
