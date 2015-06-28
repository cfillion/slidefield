#include "registry.hpp"

#include "errors.hpp"

using namespace sfl;

void registry::add(const definition &def)
{
  if(count(def.name()))
    throw duplicate_definition();

  m_definitions.insert({def.name(), def});
}
