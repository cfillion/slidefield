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

protected:
  void keyPressEvent(QKeyEvent *) override;
  void paintEvent(QPaintEvent *) override;
  void changeEvent(QEvent *) override;

private:
  void transform(QPainter &, const double win_w, const double win_h);

  void update_title();

  QString m_caption;
  QTimer *m_timer;
};

#endif
