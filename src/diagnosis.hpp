#ifndef SFL_DIAGNOSIS_HPP
#define SFL_DIAGNOSIS_HPP

#include <ostream>

namespace sfl {
  class diagnosis {
  public:
    enum level { error, warning, note };

    diagnosis(const level lvl, const std::string &msg)
      : m_level(lvl), m_message(msg) {}

    enum level level() const { return m_level; }
    const std::string &message() const { return m_message; }

  private:
    enum level m_level;
    std::string m_message;
  };

  bool operator==(const diagnosis &left, const diagnosis &right);
  bool operator!=(const diagnosis &left, const diagnosis &right);
  std::ostream &operator<<(std::ostream &os, const diagnosis &value);
};

#endif
