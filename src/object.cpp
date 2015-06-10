#include "object.hpp"

#include <boost/format.hpp>

#include "doctor.hpp"
#include "errors.hpp"

using namespace sfl;
using namespace boost;

object::object(const std::string &name)
  : m_type_id(-1), m_name(name)
{
  SFL_ERROR_AT(format("unknown object name '%s'") % name);
  throw unknown_object_error();
}
