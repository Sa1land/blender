/* SPDX-FileCopyrightText: 2023 Blender Authors
 *
 * SPDX-License-Identifier: GPL-2.0-or-later */

/** \file
 * \ingroup bke
 */

#pragma once

#ifdef WITH_OPENVDB

#  include <openvdb/openvdb.h>              /* IWYU pragma: export */
#  include <openvdb/points/PointDataGrid.h> /* IWYU pragma: export */
#  include <optional>

#  include "BLI_bounds_types.hh"
#  include "BLI_math_matrix_types.hh"
#  include "BLI_math_vector_types.hh"
#  include "BLI_parameter_pack_utils.hh"
#  include "BLI_string_ref.hh"

#  include "BKE_volume_enums.hh"
#  include "BKE_volume_grid_fwd.hh"

#  include "openvdb_fwd.hh"

struct Volume;

blender::bke::VolumeGridData *BKE_volume_grid_add_vdb(Volume &volume,
                                                      blender::StringRef name,
                                                      openvdb::GridBase::Ptr vdb_grid);

void BKE_volume_metadata_set(Volume &volume, openvdb::MetaMap::Ptr metadata);

std::optional<blender::Bounds<blender::float3>> BKE_volume_grid_bounds(
    openvdb::GridBase::ConstPtr grid);

/**
 * Return a new grid pointer with only the metadata and transform changed.
 * This is useful for instances, where there is a separate transform on top of the original
 * grid transform that must be applied for some operations that only take a grid argument.
 */
openvdb::GridBase::ConstPtr BKE_volume_grid_shallow_transform(openvdb::GridBase::ConstPtr grid,
                                                              const blender::float4x4 &transform);

blender::float4x4 BKE_volume_transform_to_blender(const openvdb::math::Transform &transform);
openvdb::math::Transform BKE_volume_transform_to_openvdb(const blender::float4x4 &transform);

template<typename OpType>
auto BKE_volume_grid_type_operation(const VolumeGridType grid_type, OpType &&op)
{
  switch (grid_type) {
    case VOLUME_GRID_FLOAT:
      return op.template operator()<openvdb::FloatGrid>();
    case VOLUME_GRID_VECTOR_FLOAT:
      return op.template operator()<openvdb::Vec3fGrid>();
    case VOLUME_GRID_BOOLEAN:
      return op.template operator()<openvdb::BoolGrid>();
    case VOLUME_GRID_DOUBLE:
      return op.template operator()<openvdb::DoubleGrid>();
    case VOLUME_GRID_INT:
      return op.template operator()<openvdb::Int32Grid>();
    case VOLUME_GRID_INT64:
      return op.template operator()<openvdb::Int64Grid>();
    case VOLUME_GRID_VECTOR_INT:
      return op.template operator()<openvdb::Vec3IGrid>();
    case VOLUME_GRID_VECTOR_DOUBLE:
      return op.template operator()<openvdb::Vec3dGrid>();
    case VOLUME_GRID_MASK:
      return op.template operator()<openvdb::MaskGrid>();
    case VOLUME_GRID_POINTS:
      return op.template operator()<openvdb::points::PointDataGrid>();
    case VOLUME_GRID_UNKNOWN:
      break;
  }

  /* Should never be called. */
  BLI_assert_msg(0, "should never be reached");
  return op.template operator()<openvdb::FloatGrid>();
}

template<typename Fn>
void BKE_volume_grid_type_to_static_type(const VolumeGridType grid_type, Fn &&fn)
{
  switch (grid_type) {
    case VOLUME_GRID_FLOAT:
      return fn(blender::TypeTag<openvdb::FloatGrid>());
    case VOLUME_GRID_VECTOR_FLOAT:
      return fn(blender::TypeTag<openvdb::Vec3fGrid>());
    case VOLUME_GRID_BOOLEAN:
      return fn(blender::TypeTag<openvdb::BoolGrid>());
    case VOLUME_GRID_DOUBLE:
      return fn(blender::TypeTag<openvdb::DoubleGrid>());
    case VOLUME_GRID_INT:
      return fn(blender::TypeTag<openvdb::Int32Grid>());
    case VOLUME_GRID_INT64:
      return fn(blender::TypeTag<openvdb::Int64Grid>());
    case VOLUME_GRID_VECTOR_INT:
      return fn(blender::TypeTag<openvdb::Vec3IGrid>());
    case VOLUME_GRID_VECTOR_DOUBLE:
      return fn(blender::TypeTag<openvdb::Vec3dGrid>());
    case VOLUME_GRID_MASK:
      return fn(blender::TypeTag<openvdb::MaskGrid>());
    case VOLUME_GRID_POINTS:
      return fn(blender::TypeTag<openvdb::points::PointDataGrid>());
    case VOLUME_GRID_UNKNOWN:
      break;
  }
  BLI_assert_unreachable();
}

openvdb::GridBase::Ptr BKE_volume_grid_create_with_changed_resolution(
    const VolumeGridType grid_type, const openvdb::GridBase &old_grid, float resolution_factor);

#endif
