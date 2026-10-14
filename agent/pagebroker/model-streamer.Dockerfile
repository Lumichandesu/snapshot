# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# Fetch the release SDK once for both native and container builds. The archive
# keeps its headers and libraries together and is rechecked by the image build.
FROM ubuntu:24.04@sha256:224a1869083a311ef3f13648a154ba79832fbef6364d31493642ca03082da254 AS download
ARG MODEL_STREAMER_VERSION=0.17.0
ARG MODEL_STREAMER_REF=dd9e5d34f966cc2667c9f0505262050b4bedc35a
WORKDIR /out
COPY model-streamer-sdk.sha256 /tmp/model-streamer-sdk.sha256
ADD https://github.com/dsx-ai-factory/model-streamer/releases/download/${MODEL_STREAMER_VERSION}/runai-model-streamer-cpp-sdk-${MODEL_STREAMER_VERSION}-linux-x86_64.tar.gz /out/sdk.tar.gz
RUN sha256sum -c /tmp/model-streamer-sdk.sha256 \
    && tar -xzf sdk.tar.gz --strip-components=1 \
      runai-model-streamer-cpp-sdk-${MODEL_STREAMER_VERSION}-linux-x86_64/include \
      runai-model-streamer-cpp-sdk-${MODEL_STREAMER_VERSION}-linux-x86_64/lib/libstreamer.so \
      runai-model-streamer-cpp-sdk-${MODEL_STREAMER_VERSION}-linux-x86_64/lib/libstreamers3.so \
      runai-model-streamer-cpp-sdk-${MODEL_STREAMER_VERSION}-linux-x86_64/LICENSE \
    && mkdir -p legal \
    && mv LICENSE legal/LICENSE \
    && cp /tmp/model-streamer-sdk.sha256 legal/SDK.sha256 \
    && printf '%s\n' "${MODEL_STREAMER_VERSION}" > legal/VERSION \
    && printf '%s\n' "${MODEL_STREAMER_REF}" > legal/REVISION

# Preserve the release source and the two I/O libraries statically linked into
# libstreamer.so. These are source downloads only; no toolchain is needed.
ADD --checksum=sha256:c344e2ee677a3c3e4cb65fc7ab1e04918d85c2f7268e9d4465a895cea2082499 https://codeload.github.com/dsx-ai-factory/model-streamer/tar.gz/${MODEL_STREAMER_REF} /out/legal/source/model-streamer.tar.gz
ADD --checksum=sha256:2c44d1c5fd0d43752287c9ae1eb9c023f04ef848ea8d4aafa46e9aedb678200b https://deb.debian.org/debian/pool/main/liba/libaio/libaio_0.3.113.orig.tar.gz /out/legal/source/libaio.tar.gz
ADD --checksum=sha256:5f80964108981c6ad979c735f0b4877d5f49914c2a062f8e88282f26bf61de0c https://github.com/axboe/liburing/archive/refs/tags/liburing-2.14.tar.gz /out/legal/source/liburing.tar.gz

FROM scratch AS artifacts
COPY --from=download /out/ /
