#ifndef WINDOW_HPP
#define WINDOW_HPP

#include <QWidget>
#include <string>

class window : public QWidget
{
public:
  window(const std::string &caption);

  QSize sizeHint() const override;

public Q_SLOTS:
  void update();
  void toggle_fullscreen();

protected:
  void keyPressEvent(QKeyEvent *) override;
  void paintEvent(QPaintEvent *) override;
  void changeEvent(QEvent *) override;

private:
  void setup_actions();
  void update_title();

  void transform(QPainter &, const double win_w, const double win_h);

  QString m_caption;
  QTimer *m_timer;

  QAction *m_fullscreen;
  QAction *m_quit;
};

#endif
