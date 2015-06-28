#ifndef SFL_REGISTRY_HPP
#define SFL_REGISTRY_HPP

#include <string>
#include <unordered_map>

namespace sfl {
  class definition {
  public:
    definition(const std::string &name, const int user = -1)
      : m_name(name), m_user(user) {}

    const std::string &name() const { return m_name; }
    int user() const { return m_user; }

  private:
    std::string m_name;
    int m_user;
  };

  typedef std::unordered_map<std::string, definition> definition_map;

  class registry {
  public:
    registry() {}

    const definition &at(const std::string &k) const
    { return m_definitions.at(k); }

    void add(const definition &d);
    int count(const std::string &k) { return m_definitions.count(k); }

  private:
    definition_map m_definitions;
  };
};

#endif
