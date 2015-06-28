#include "object.hpp"

#include <boost/format.hpp>

#include "doctor.hpp"
#include "errors.hpp"

using namespace sfl;
using namespace boost;

object::object(const std::string &name, const sfl::location &loc)
  : m_location(loc)
{
  const registry *reg = location().registry();

  if(!reg)
    throw missing_registry();

  if(!reg->count(name)) {
    error_at(location(), format("unknown object name '%s'") % name);
    throw unknown_object();
  }

  m_definition = &reg->at(name);
}
