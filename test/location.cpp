#include "vendor/catch.hpp"

#include "../src/location.hpp"

using namespace sfl;

static const char *M = "[location]";

TEST_CASE("default context", M) {
  const context c{};

  REQUIRE(c.doctor == 0);
}

TEST_CASE("compare contextes", M) {
  SECTION("by doctors") {
    const context a{(doctor*)0x1, 0};
    const context b{(doctor*)0x2, 0};

    REQUIRE(a == a);
    REQUIRE_FALSE(a == b);

    REQUIRE_FALSE(a != a);
    REQUIRE(a != b);
  }

  SECTION("by registry") {
    const context a{0, (registry*)0x1};
    const context b{0, (registry*)0x2};

    REQUIRE(a == a);
    REQUIRE_FALSE(a == b);

    REQUIRE_FALSE(a != a);
    REQUIRE(a != b);
  }
}

TEST_CASE("extract data", M) {
  doctor *fake_doc = (doctor*)0x1;
  registry *fake_reg = (registry*)0x2;

  context c({fake_doc, fake_reg});
  location l(c);

  REQUIRE(l.doctor() == fake_doc);
  REQUIRE(l.registry() == fake_reg);
}

TEST_CASE("compare locations", M) {
  SECTION("by context") {
    const location a;
    const location b({(doctor*)0x42, 0});

    REQUIRE(a == a);
    REQUIRE_FALSE(a == b);

    REQUIRE_FALSE(a != a);
    REQUIRE(a != b);
  }
}

TEST_CASE("default location", M) {
  const location a;
  REQUIRE(a.doctor() == 0);
}
