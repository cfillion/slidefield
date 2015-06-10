#ifndef SFL_OBJECT_HPP
#define SFL_OBJECT_HPP

#include <string>

namespace sfl {
  class object
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
