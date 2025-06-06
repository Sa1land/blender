/* SPDX-FileCopyrightText: 2023 Blender Authors
 *
 * SPDX-License-Identifier: GPL-2.0-or-later */

/** \file
 * \ingroup bke
 */

#pragma once

/**
 * A #ViewerPath is a path to data that is viewed/debugged by the user. It is a list of
 * #ViewerPathElem.
 *
 * This is only used for geometry nodes currently. When the user activates a viewer node the
 * corresponding path contains the following elements:
 * - Object the viewer is activated on.
 * - Modifier that contains the corresponding geometry node group.
 * - Node tree path in case the viewer node is in a nested node group.
 * - Viewer node name.
 *
 * The entire path is necessary (instead of just the combination of node group and viewer name),
 * because the same node group may be used in many different places.
 *
 * This file contains basic functions for creating/deleting a #ViewerPath. For more use-case
 * specific functions look in `ED_viewer_path.hh`.
 */

#include "DNA_viewer_path_types.h"

struct BlendWriter;
struct BlendDataReader;
struct LibraryForeachIDData;

namespace blender::bke::id {
class IDRemapper;
}

enum ViewerPathEqualFlag {
  VIEWER_PATH_EQUAL_FLAG_IGNORE_ITERATION = (1 << 0),
  VIEWER_PATH_EQUAL_FLAG_CONSIDER_UI_NAME = (1 << 1),
};

void BKE_viewer_path_init(ViewerPath *viewer_path);
void BKE_viewer_path_clear(ViewerPath *viewer_path);
void BKE_viewer_path_copy(ViewerPath *dst, const ViewerPath *src);
bool BKE_viewer_path_equal(const ViewerPath *a,
                           const ViewerPath *b,
                           ViewerPathEqualFlag flag = ViewerPathEqualFlag(0));
uint64_t BKE_viewer_path_hash(const ViewerPath &viewer_path);
void BKE_viewer_path_blend_write(BlendWriter *writer, const ViewerPath *viewer_path);
void BKE_viewer_path_blend_read_data(BlendDataReader *reader, ViewerPath *viewer_path);
void BKE_viewer_path_foreach_id(LibraryForeachIDData *data, ViewerPath *viewer_path);
void BKE_viewer_path_id_remap(ViewerPath *viewer_path,
                              const blender::bke::id::IDRemapper &mappings);

ViewerPathElem *BKE_viewer_path_elem_new(ViewerPathElemType type);
IDViewerPathElem *BKE_viewer_path_elem_new_id();
ModifierViewerPathElem *BKE_viewer_path_elem_new_modifier();
GroupNodeViewerPathElem *BKE_viewer_path_elem_new_group_node();
SimulationZoneViewerPathElem *BKE_viewer_path_elem_new_simulation_zone();
ViewerNodeViewerPathElem *BKE_viewer_path_elem_new_viewer_node();
RepeatZoneViewerPathElem *BKE_viewer_path_elem_new_repeat_zone();
ForeachGeometryElementZoneViewerPathElem *BKE_viewer_path_elem_new_foreach_geometry_element_zone();
EvaluateClosureNodeViewerPathElem *BKE_viewer_path_elem_new_evaluate_closure();

ViewerPathElem *BKE_viewer_path_elem_copy(const ViewerPathElem *src);
bool BKE_viewer_path_elem_equal(const ViewerPathElem *a,
                                const ViewerPathElem *b,
                                ViewerPathEqualFlag flag = ViewerPathEqualFlag(0));
uint64_t BKE_viewer_path_elem_hash(const ViewerPathElem &elem);
void BKE_viewer_path_elem_free(ViewerPathElem *elem);
