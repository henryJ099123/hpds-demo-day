GLFW_FLAGS:= -lglfw -I/opt/homebrew/include -L/opt/homebrew/lib
METAL_FLAGS:= -framework Cocoa -framework Metal -framework MetalKit -framework QuartzCore -I ../../metal-cpp

all: main triangle.metallib

%.metallib: %.metalar
	xcrun -sdk macosx metallib -o $@ $<

main: main.mm mtl_implementation.cpp mtl_engine.mm
	clang++ --std=c++17 -fobjc-arc $(GLFW_FLAGS) $(METAL_FLAGS) $^ -o $@

%.air: %.metal
	xcrun -sdk macosx metal -c -O2 -o $@ $<

%.metalar: %.air
	xcrun -sdk macosx metal-ar r $@ $<

clean:
	rm -f main
	rm -f *.air
	rm -f *.metalar
	rm -f *.metallib
