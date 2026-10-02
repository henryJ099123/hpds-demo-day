# These are the minimally required frameworks for this to work.
METAL_FLAGS:= -I ../metal-cpp -framework Metal -framework QuartzCore

all: main add.metallib

main: main.cpp
	clang++ --std=c++17 $(METAL_FLAGS) $^ -o $@ -fobjc-arc 

%.air: %.metal
	xcrun -sdk macosx metal -c -O2 -o $@ $<

%.metallib: %.air
	xcrun -sdk macosx metallib -o $@ $<

# Remove the above two rules and replace with the bottom two
# if you decide to add multiple .metal files.
# %.metalar: %.air
#	xcrun -sdk macosx metal-ar r $@ $<
# %.air: %.metal
# 	xcrun -sdk macosx metallib -o $@ $<

clean:
	rm -f main
	rm -f *.air
	rm -f *.metalar
	rm -f *.metallib
