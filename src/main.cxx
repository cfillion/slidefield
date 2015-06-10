#include <boost/program_options.hpp>
#include <iostream>
#include <sys/ioctl.h>

#include "window.hpp"

using namespace boost;
using namespace std;

int main(int argc, char *argv[])
{
  namespace po = program_options;

  const string caption = "SlideField v0.3";

  struct winsize w;
  ioctl(STDOUT_FILENO, TIOCGWINSZ, &w);

  po::options_description desc(caption, w.ws_col);
  desc.add_options()
    ("help,h", "display this help and exit")
    ("version,v", "output version information and exit")
  ;

  po::variables_map opts;

  try {
    po::store(po::parse_command_line(argc, argv, desc), opts);
    po::notify(opts);
  }
  catch(po::error &err) {
    cerr << err.what() << endl;
    return EXIT_FAILURE;
  }

  if(opts.count("help")) {
    cout << desc;
    return EXIT_SUCCESS;
  }

  if(opts.count("version")) {
    cout << caption << endl;
    return EXIT_SUCCESS;
  }

  try {
    window win(caption);
    win.show();
  }
  catch(const window_error &e) {
    cerr << e.what() << endl;
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}
