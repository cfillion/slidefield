#include "vendor/catch.hpp"

#include "../src/errors.hpp"
#include "../src/object.hpp"

using namespace sfl;

static const char *M = "[object]";

TEST_CASE("unregistered object", M) {
  try {
    object obj("qwfpgjluy");
    FAIL("exception not thrown");
  }
  catch(const unknown_object_error &e) {
    REQUIRE(e.cause() == diagnosis(diagnosis::error,
      "unknown object name 'qwfpgjluy'"));
  }
}
