#ifndef SFL_ERRORS_HPP
#define SFL_ERRORS_HPP

#define ERROR_TYPE(type) class type : public error {};

namespace sfl {
  class error {};

  ERROR_TYPE(duplicate_definition);
  ERROR_TYPE(missing_doctor);
  ERROR_TYPE(unknown_object);

  // new paragraph to sort the error types easily
};

#undef ERROR_TYPE

#endif
