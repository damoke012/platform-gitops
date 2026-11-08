# llama.cpp server built for the lab's Tesla P40 (compute capability 6.1) on CUDA 12.2, the newest the
# node's driver (535.261) supports. Upstream server-cuda images target newer CUDA and architectures.
# Base images from Docker Hub: nvcr.io is unreachable from ocp-svc (connection timeout, 2026-11-08).
# Written 2026-11-08. Build on ocp-svc:  podman build -t llama-cpp-p40:<tag> images/llama-cpp-p40
ARG CUDA=12.2.2
FROM docker.io/nvidia/cuda:${CUDA}-devel-ubuntu22.04 AS build
RUN apt-get update && apt-get install -y --no-install-recommends git cmake build-essential ca-certificates \
    && rm -rf /var/lib/apt/lists/*
ARG LLAMA_TAG=b7472
RUN git clone --depth 1 --branch ${LLAMA_TAG} https://github.com/ggml-org/llama.cpp /src
WORKDIR /src
# --allow-shlib-undefined: there is no GPU driver (libcuda.so.1) in a build container; the runtime gets it
# from the node. Same flag as upstream's .devops/cuda.Dockerfile.
RUN cmake -B build -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=61 -DGGML_NATIVE=OFF -DLLAMA_CURL=OFF \
      -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF -DLLAMA_BUILD_SERVER=ON \
      -DCMAKE_EXE_LINKER_FLAGS=-Wl,--allow-shlib-undefined
# Two steps so the slow CUDA kernels (~25 min on 4 cores) stay cached if the server link fails.
RUN cmake --build build --config Release -j"$(nproc)" --target ggml-cuda
# CPU side: the lab's Xeon E5-2670 (Sandy Bridge) has AVX but no AVX2/FMA/F16C/BMI2; the default build dies with
# SIGILL (exit 132). Set here, after the CUDA step, so the cached kernels are reused.
RUN cmake -B build -DGGML_AVX=ON -DGGML_AVX2=OFF -DGGML_FMA=OFF -DGGML_F16C=OFF -DGGML_AVX512=OFF -DGGML_BMI2=OFF \
    && cmake --build build --config Release -j"$(nproc)" --target llama-server \
    && mkdir /out && cp build/bin/llama-server /out/ && find build -name '*.so*' -exec cp -P {} /out/ \;

FROM docker.io/nvidia/cuda:${CUDA}-runtime-ubuntu22.04
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends libgomp1 curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /out/ /usr/local/lib/llama/
RUN ln -s /usr/local/lib/llama/llama-server /usr/local/bin/llama-server \
    && echo /usr/local/lib/llama > /etc/ld.so.conf.d/llama.conf && ldconfig
USER 1001
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/llama-server"]
