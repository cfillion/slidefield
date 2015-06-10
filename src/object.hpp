#ifndef SFL_OBJECT_HPP
#define SFL_OBJECT_HPP

#include "doctor.hpp"

namespace sfl {
  class object : private doctor
  {
  public:
    object(const std::string &name);

    int type_id() const { return m_type_id; }
    const std::string &name() const { return m_name; }

  private:
    int m_type_id;
    std::string m_name;
  };
};

#endif
