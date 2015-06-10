#include "vendor/catch.hpp"
#include "../src/errors.hpp"

using namespace sfl;

TEST_CASE("custom exceptions", "[errors]") {
  const diagnosis dia(diagnosis::error, "hello world");
  error err(dia);

  const diagnosis cause = err.cause();
  const char *what = err.what();

  REQUIRE(cause == dia);
  REQUIRE(std::string(what) == dia.message());
}
