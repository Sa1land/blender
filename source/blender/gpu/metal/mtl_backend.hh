/* SPDX-FileCopyrightText: 2023 Blender Authors
 *
 * SPDX-License-Identifier: GPL-2.0-or-later */

/** \file
 * \ingroup gpu
 */

#pragma once

#include "BLI_vector.hh"

#include "gpu_backend.hh"
#include "gpu_shader_private.hh"
#include "mtl_capabilities.hh"

namespace blender::gpu {

class Batch;
class FrameBuffer;
class QueryPool;
class Shader;
class UniformBuf;
class VertBuf;
class MTLContext;

class MTLBackend : public GPUBackend {
  friend class MTLContext;

 public:
  /* Capabilities. */
  static MTLCapabilities capabilities;

  static MTLCapabilities &get_capabilities()
  {
    return MTLBackend::capabilities;
  }

  ~MTLBackend() override
  {
    MTLBackend::platform_exit();
  }

  void init_resources() override;

  void delete_resources() override;

  static bool metal_is_supported();
  static MTLBackend *get()
  {
    return static_cast<MTLBackend *>(GPUBackend::get());
  }

  void samplers_update() override;
  void compute_dispatch(int groups_x_len, int groups_y_len, int groups_z_len) override;
  void compute_dispatch_indirect(StorageBuf *indirect_buf) override;

  /* MTL Allocators need to be implemented in separate `.mm` files,
   * due to allocation of Objective-C objects. */
  Context *context_alloc(void *ghost_window, void *ghost_context) override;
  Batch *batch_alloc() override;
  Fence *fence_alloc() override;
  FrameBuffer *framebuffer_alloc(const char *name) override;
  IndexBuf *indexbuf_alloc() override;
  PixelBuffer *pixelbuf_alloc(size_t size) override;
  QueryPool *querypool_alloc() override;
  Shader *shader_alloc(const char *name) override;
  Texture *texture_alloc(const char *name) override;
  UniformBuf *uniformbuf_alloc(size_t size, const char *name) override;
  StorageBuf *storagebuf_alloc(size_t size, GPUUsageType usage, const char *name) override;
  VertBuf *vertbuf_alloc() override;
  void shader_cache_dir_clear_old() override {}

  /* Render Frame Coordination. */
  void render_begin() override;
  void render_end() override;
  void render_step(bool force_resource_release = false) override;
  bool is_inside_render_boundary();

 private:
  static void platform_init(MTLContext *ctx);
  static void platform_exit();

  static void capabilities_init(MTLContext *ctx);
};

}  // namespace blender::gpu
