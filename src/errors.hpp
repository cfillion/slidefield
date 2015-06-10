#ifndef SFL_ERRORS_HPP
#define SFL_ERRORS_HPP

#include "diagnosis.hpp"

#define ERROR_TYPE(type) class type : public error { \
  public: type(const diagnosis &ds) : error(ds) {} }

namespace sfl {
  class error : public std::runtime_error
  {
  public:
    error(const diagnosis &ds)
      : std::runtime_error(ds.message().c_str()), m_diagnosis(ds) {}

    const diagnosis &cause() const { return m_diagnosis; }

  private:
    diagnosis m_diagnosis;
  };

  ERROR_TYPE(unknown_object_error);
};

#undef ERROR_TYPE

#endif
