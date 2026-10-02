// Metal shading language: C++ variant for GPUs.

// [[thread_position_in_grid]] is a cpp attribute for the index (it does it for you), unlike
// with CUDA.

// buffer(i) tells Metal where each of the arguments are in the buffer set by the CPU.
// kernel keyword indicates a kernel function.
kernel void add_arrays(device const float* a [[buffer(0)]],
                       device const float* b [[buffer(1)]],
                       device float* result  [[buffer(2)]],
                       uint i [[thread_position_in_grid]]) {
    result[i] = a[i] + b[i];
}
