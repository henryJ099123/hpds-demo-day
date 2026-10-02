#include <Metal/Metal.hpp>
#include <iostream>
#include "mtl_engine.hpp"

int main(int argc, const char* argv[]) {
    MTLEngine engine;
    engine.init();
    engine.run();
    engine.cleanup();

    std::cout << "Hello world from Metal CPP\n";
    return 0;
}
