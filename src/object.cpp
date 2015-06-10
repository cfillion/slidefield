#include "object.hpp"

#include <boost/format.hpp>

#include "errors.hpp"

using namespace sfl;
using namespace boost;

object::object(const std::string &name)
  : m_type_id(-1), m_name(name)
{
  throw unknown_object_error(error_at(
    format("unknown object name '%s'") % name
  ));
}
