#include "vendor/catch.hpp"

#include "../src/location.hpp"

using namespace sfl;

static const char *M = "[location]";

TEST_CASE("default context", M) {
  const context c{};

  REQUIRE(c.doctor == 0);
}

TEST_CASE("compare contextes", M) {
  const context a{(doctor*)0x1};
  const context b{(doctor*)0x2};

  REQUIRE(a == a);
  REQUIRE_FALSE(a == b);

  REQUIRE_FALSE(a != a);
  REQUIRE(a != b);
}

TEST_CASE("extract data", M) {
  doctor *fake_doc = (doctor*)0x42;
  context c({fake_doc});
  location l(c);

  REQUIRE(l.context() == c);
  REQUIRE(l.doctor() == fake_doc);
}

TEST_CASE("compare locations", M) {
  const location a;
  const context b({(doctor*)0x42});

  REQUIRE(a == a);
  REQUIRE_FALSE(a == b);

  REQUIRE_FALSE(a != a);
  REQUIRE(a != b);
}
