#include "vendor/catch.hpp"

#include "../src/errors.hpp"
#include "../src/object.hpp"
#include "../src/doctor.hpp"

using namespace sfl;

static const char *M = "[object]";

TEST_CASE("unregistered object", M) {
  doctor doc;
  location loc({&doc});

  REQUIRE_THROWS_AS({
    object obj("qwfpgjluy", loc);
  }, unknown_object_error);

  diagnosis_bag bag = doc.bag();

  REQUIRE(bag.size() == 1);
  REQUIRE(bag.at(0) ==
    diagnosis(diagnosis::error, "unknown object name 'qwfpgjluy'")
  );
}
