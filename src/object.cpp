#include "object.hpp"

#include <boost/format.hpp>

#include "doctor.hpp"
#include "errors.hpp"

using namespace sfl;
using namespace boost;

object::object(const std::string &name, const sfl::location &loc)
  : m_type_id(-1), m_name(name), m_location(loc)
{
  error_at(location(), format("unknown object name '%s'") % name);
  throw unknown_object_error();
}
