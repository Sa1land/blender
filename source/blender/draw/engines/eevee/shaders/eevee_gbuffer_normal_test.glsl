/* SPDX-FileCopyrightText: 2023 Blender Authors
 *
 * SPDX-License-Identifier: GPL-2.0-or-later */

/* Directive for resetting the line numbering so the failing tests lines can be printed.
 * This conflict with the shader compiler error logging scheme.
 * Comment out for correct compilation error line. */
#line 9

#include "eevee_gbuffer_lib.glsl"
#include "gpu_shader_test_lib.glsl"

#define TEST(a, b) if (true)

GBufferData gbuffer_new()
{
  GBufferData data;
  data.closure[0].weight = 0.0f;
  data.closure[1].weight = 0.0f;
  data.closure[2].weight = 0.0f;
  data.thickness = 0.2f;
  data.surface_N = normalize(float3(0.1f, 0.2f, 0.3f));
  return data;
}

void main()
{
  float3 Ng = float3(1.0f, 0.0f, 0.0f);

  TEST(eevee_gbuffer, NormalPack)
  {
    GBufferWriter gbuf;
    gbuf.header = 0u;
    gbuf.bins_len = 0;
    gbuf.data_len = 0;
    gbuf.normal_len = 0;

    float3 N0 = normalize(float3(0.2f, 0.1f, 0.3f));
    float3 N1 = normalize(float3(0.1f, 0.2f, 0.3f));
    float3 N2 = normalize(float3(0.3f, 0.1f, 0.2f));

    gbuffer_append_closure(gbuf, GBUF_DIFFUSE);
    gbuffer_append_normal(gbuf, N0);

    EXPECT_EQ(gbuf.bins_len, 1);
    EXPECT_EQ(gbuf.normal_len, 1);
    EXPECT_EQ(gbuf.N[0], gbuffer_normal_pack(N0));

    gbuffer_append_closure(gbuf, GBUF_DIFFUSE);
    gbuffer_append_normal(gbuf, N1);

    EXPECT_EQ(gbuf.bins_len, 2);
    EXPECT_EQ(gbuf.normal_len, 2);
    EXPECT_EQ(gbuf.N[1], gbuffer_normal_pack(N1));

    gbuffer_append_closure(gbuf, GBUF_DIFFUSE);
    gbuffer_append_normal(gbuf, N2);

    EXPECT_EQ(gbuf.bins_len, 3);
    EXPECT_EQ(gbuf.normal_len, 3);
    EXPECT_EQ(gbuf.N[2], gbuffer_normal_pack(N2));
  }

  TEST(eevee_gbuffer, NormalPackOpti)
  {
    GBufferWriter gbuf;
    gbuf.header = 0u;
    gbuf.bins_len = 0;
    gbuf.data_len = 0;
    gbuf.normal_len = 0;

    float3 N0 = normalize(float3(0.2f, 0.1f, 0.3f));

    gbuffer_append_closure(gbuf, GBUF_DIFFUSE);
    gbuffer_append_normal(gbuf, N0);

    EXPECT_EQ(gbuf.bins_len, 1);
    EXPECT_EQ(gbuf.normal_len, 1);
    EXPECT_EQ(gbuf.N[0], gbuffer_normal_pack(N0));

    gbuffer_append_closure(gbuf, GBUF_DIFFUSE);
    gbuffer_append_normal(gbuf, N0);

    EXPECT_EQ(gbuf.bins_len, 2);
    EXPECT_EQ(gbuf.normal_len, 1);

    gbuffer_append_closure(gbuf, GBUF_DIFFUSE);
    gbuffer_append_normal(gbuf, N0);

    EXPECT_EQ(gbuf.bins_len, 3);
    EXPECT_EQ(gbuf.normal_len, 1);
  }

  GBufferData data_in;
  GBufferReader data_out;
  samplerGBufferHeader header_tx = 0;
  samplerGBufferClosure closure_tx = 0;
  samplerGBufferNormal normal_tx = 0;

  ClosureUndetermined cl1 = closure_new(CLOSURE_BSDF_DIFFUSE_ID);
  cl1.weight = 1.0f;
  cl1.color = float3(1);
  cl1.N = normalize(float3(0.2f, 0.1f, 0.3f));

  ClosureUndetermined cl2 = closure_new(CLOSURE_BSDF_DIFFUSE_ID);
  cl2.weight = 1.0f;
  cl2.color = float3(1);
  cl2.N = normalize(float3(0.1f, 0.2f, 0.3f));

  ClosureUndetermined cl3 = closure_new(CLOSURE_BSDF_DIFFUSE_ID);
  cl3.weight = 1.0f;
  cl3.color = float3(1);
  cl3.N = normalize(float3(0.3f, 0.2f, 0.1f));

  ClosureUndetermined cl_none = closure_new(CLOSURE_NONE_ID);
  cl_none.weight = 1.0f;
  cl_none.color = float3(1);
  cl_none.N = normalize(float3(0.0f, 0.0f, 1.0f));

  TEST(eevee_gbuffer, NormalReuseDoubleFirst)
  {
    data_in = gbuffer_new();
    data_in.closure[0] = cl1;
    data_in.closure[1] = cl1;

    g_data_packed = gbuffer_pack(data_in, Ng);

    EXPECT_EQ(g_data_packed.data_len, 2);
    EXPECT_EQ(g_data_packed.normal_len, 1);

    data_out = gbuffer_read(header_tx, closure_tx, normal_tx, int2(0));

    EXPECT_EQ(data_out.closure_count, 2);
    EXPECT_EQ(data_out.normal_len, 1);
    EXPECT_NEAR(cl1.N, gbuffer_closure_get(data_out, 0).N, 1e-5f);
    EXPECT_NEAR(cl1.N, gbuffer_closure_get(data_out, 1).N, 1e-5f);
  }

  TEST(eevee_gbuffer, NormalReuseDoubleNone)
  {
    data_in = gbuffer_new();
    data_in.closure[0] = cl1;
    data_in.closure[1] = cl2;

    g_data_packed = gbuffer_pack(data_in, Ng);

    EXPECT_EQ(g_data_packed.data_len, 2);
    EXPECT_EQ(g_data_packed.normal_len, 2);

    data_out = gbuffer_read(header_tx, closure_tx, normal_tx, int2(0));

    EXPECT_EQ(data_out.closure_count, 2);
    EXPECT_EQ(data_out.normal_len, 2);
    EXPECT_NEAR(cl1.N, gbuffer_closure_get(data_out, 0).N, 1e-5f);
    EXPECT_NEAR(cl2.N, gbuffer_closure_get(data_out, 1).N, 1e-5f);
  }

  TEST(eevee_gbuffer, NormalReuseTripleFirst)
  {
    data_in = gbuffer_new();
    data_in.closure[0] = cl1;
    data_in.closure[1] = cl2;
    data_in.closure[2] = cl2;

    g_data_packed = gbuffer_pack(data_in, Ng);

    EXPECT_EQ(g_data_packed.normal_len, 2);

    data_out = gbuffer_read(header_tx, closure_tx, normal_tx, int2(0));

    EXPECT_EQ(data_out.closure_count, 3);
    EXPECT_EQ(data_out.normal_len, 2);
    EXPECT_NEAR(cl1.N, gbuffer_closure_get(data_out, 0).N, 1e-5f);
    EXPECT_NEAR(cl2.N, gbuffer_closure_get(data_out, 1).N, 1e-5f);
    EXPECT_NEAR(cl2.N, gbuffer_closure_get(data_out, 2).N, 1e-5f);
  }

  TEST(eevee_gbuffer, NormalReuseTripleSecond)
  {
    data_in = gbuffer_new();
    data_in.closure[0] = cl2;
    data_in.closure[1] = cl1;
    data_in.closure[2] = cl2;

    g_data_packed = gbuffer_pack(data_in, Ng);

    EXPECT_EQ(g_data_packed.normal_len, 2);

    data_out = gbuffer_read(header_tx, closure_tx, normal_tx, int2(0));

    EXPECT_EQ(data_out.closure_count, 3);
    EXPECT_EQ(data_out.normal_len, 2);
    EXPECT_NEAR(cl2.N, gbuffer_closure_get(data_out, 0).N, 1e-5f);
    EXPECT_NEAR(cl1.N, gbuffer_closure_get(data_out, 1).N, 1e-5f);
    EXPECT_NEAR(cl2.N, gbuffer_closure_get(data_out, 2).N, 1e-5f);
  }

  TEST(eevee_gbuffer, NormalReuseTripleThird)
  {
    data_in = gbuffer_new();
    data_in.closure[0] = cl2;
    data_in.closure[1] = cl2;
    data_in.closure[2] = cl1;

    g_data_packed = gbuffer_pack(data_in, Ng);

    EXPECT_EQ(g_data_packed.normal_len, 2);

    data_out = gbuffer_read(header_tx, closure_tx, normal_tx, int2(0));

    EXPECT_EQ(data_out.closure_count, 3);
    EXPECT_EQ(data_out.normal_len, 2);
    EXPECT_NEAR(cl2.N, gbuffer_closure_get(data_out, 0).N, 1e-5f);
    EXPECT_NEAR(cl2.N, gbuffer_closure_get(data_out, 1).N, 1e-5f);
    EXPECT_NEAR(cl1.N, gbuffer_closure_get(data_out, 2).N, 1e-5f);
  }

  TEST(eevee_gbuffer, NormalReuseTripleNone)
  {
    data_in = gbuffer_new();
    data_in.closure[0] = cl1;
    data_in.closure[1] = cl2;
    data_in.closure[2] = cl3;

    g_data_packed = gbuffer_pack(data_in, Ng);

    EXPECT_EQ(g_data_packed.normal_len, 3);

    data_out = gbuffer_read(header_tx, closure_tx, normal_tx, int2(0));

    EXPECT_EQ(data_out.closure_count, 3);
    EXPECT_EQ(data_out.normal_len, 3);
    EXPECT_NEAR(cl1.N, gbuffer_closure_get(data_out, 0).N, 1e-5f);
    EXPECT_NEAR(cl2.N, gbuffer_closure_get(data_out, 1).N, 1e-5f);
    EXPECT_NEAR(cl3.N, gbuffer_closure_get(data_out, 2).N, 1e-5f);
  }

  TEST(eevee_gbuffer, NormalReuseSingleHole)
  {
    data_in = gbuffer_new();
    data_in.closure[0] = cl1;
    data_in.closure[1] = cl_none;
    data_in.closure[2] = cl3;

    g_data_packed = gbuffer_pack(data_in, Ng);

    EXPECT_EQ(g_data_packed.normal_len, 2);

    data_out = gbuffer_read(header_tx, closure_tx, normal_tx, int2(0));

    EXPECT_EQ(data_out.closure_count, 2);
    EXPECT_EQ(data_out.normal_len, 2);
    EXPECT_NEAR(cl1.N, gbuffer_closure_get(data_out, 0).N, 1e-5f);
    EXPECT_NEAR(cl3.N, gbuffer_closure_get(data_out, 1).N, 1e-5f);
    EXPECT_NEAR(cl3.N, gbuffer_closure_get_by_bin(data_out, 2).N, 1e-5f);
  }

  TEST(eevee_gbuffer, NormalReuseDoubleHole)
  {
    data_in = gbuffer_new();
    data_in.closure[0] = cl_none;
    data_in.closure[1] = cl_none;
    data_in.closure[2] = cl3;

    g_data_packed = gbuffer_pack(data_in, Ng);

    EXPECT_EQ(g_data_packed.normal_len, 1);

    data_out = gbuffer_read(header_tx, closure_tx, normal_tx, int2(0));

    EXPECT_EQ(data_out.closure_count, 1);
    EXPECT_EQ(data_out.normal_len, 1);
    EXPECT_NEAR(cl3.N, gbuffer_closure_get(data_out, 0).N, 1e-5f);
    EXPECT_NEAR(cl3.N, gbuffer_closure_get_by_bin(data_out, 2).N, 1e-5f);
  }
}
