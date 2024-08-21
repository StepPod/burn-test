# Set build arguments
ARG CUDA_VERSION=11.8.0
ARG IMAGE_DISTRO=ubuntu20.04

# Stage 1: Build the GPU stress tool
FROM nvidia/cuda:${CUDA_VERSION}-devel-${IMAGE_DISTRO} AS builder

WORKDIR /build

COPY . /build/

RUN make

# Stage 2: Final runtime image
FROM nvidia/cuda:${CUDA_VERSION}-runtime-${IMAGE_DISTRO}

# Install CPU stress testing tool
RUN apt-get update && apt-get install -y apt-utils stress && apt-get clean

# Copy GPU stress test files from the builder stage
COPY --from=builder /build/gpu_burn /app/
COPY --from=builder /build/compare.ptx /app/

WORKDIR /app

# Set default environment variables
ENV CPU_CORES=4
ENV BURN_DURATION=60
ENV VM_INSTANCES=1
ENV MEMORY_SIZE=256

# Allow customization through command-line arguments
ENTRYPOINT ["bash", "-c"]
CMD ["stress --cpu ${CPU_CORES} --timeout ${BURN_DURATION} --vm ${VM_INSTANCES} --vm-bytes ${MEMORY_SIZE}M & ./gpu_burn ${BURN_DURATION} && tail -f /dev/null"]
