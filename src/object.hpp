#ifndef SFL_OBJECT_HPP
#define SFL_OBJECT_HPP

#include <string>

#include "location.hpp"

namespace sfl {
  class object {
  public:
    object(const std::string &name, const location &loc = sfl::location());

    int type_id() const { return m_type_id; }
    const std::string &name() const { return m_name; }
    const location &location() const { return m_location; }

  private:
    int m_type_id;
    std::string m_name;
    sfl::location m_location;
  };
};

#endif
