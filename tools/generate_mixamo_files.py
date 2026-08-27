import os
import json
import struct
import math

def create_single_anim_gltf(anim_target_name, output_filename):
    # Generates individual GLTF character animation files in ASSETS/mixamo/
    # E.g., Idle.gltf, Walking.gltf, Running.gltf, Sprint.gltf

    vertices = []
    normals = []
    uvs = []
    joints = []
    weights = []
    indices = []

    def add_body_part(min_pt, max_pt, joint_idx):
        start_idx = len(vertices) // 3
        x0, y0, z0 = min_pt
        x1, y1, z1 = max_pt
        pts = [
            (x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
            (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)
        ]
        faces = [
            ([0, 1, 2, 3], 0, 0, -1),
            ([5, 4, 7, 6], 0, 0, 1),
            ([4, 0, 3, 7], -1, 0, 0),
            ([1, 5, 6, 2], 1, 0, 0),
            ([3, 2, 6, 7], 0, 1, 0),
            ([4, 5, 1, 0], 0, -1, 0)
        ]
        for quad, nx, ny, nz in faces:
            base = len(vertices) // 3
            for i in quad:
                pt = pts[i]
                vertices.extend(pt)
                normals.extend([nx, ny, nz])
                uvs.extend([0.5, 0.5])
                joints.extend([joint_idx, 0, 0, 0])
                weights.extend([1.0, 0.0, 0.0, 0.0])
            indices.extend([base, base + 1, base + 2, base, base + 2, base + 3])

    # Pelvis / Hips (0)
    add_body_part((-0.18, 0.85, -0.10), (0.18, 1.05, 0.10), 0)
    # Torso (1, 2)
    add_body_part((-0.16, 1.05, -0.09), (0.16, 1.30, 0.09), 1)
    add_body_part((-0.19, 1.30, -0.11), (0.19, 1.55, 0.11), 2)
    # Head (3) & Ponytail (14)
    add_body_part((-0.10, 1.55, -0.10), (0.10, 1.78, 0.10), 3)
    add_body_part((-0.06, 1.25, -0.30), (0.06, 1.72, -0.10), 14)
    # Legs (4..9)
    add_body_part((-0.23, 0.52, -0.08), (-0.07, 0.88, 0.08), 4)
    add_body_part((-0.21, 0.12, -0.07), (-0.09, 0.52, 0.07), 5)
    add_body_part((-0.22, 0.00, -0.18), (-0.08, 0.12, 0.06), 6)

    add_body_part((0.07, 0.52, -0.08), (0.23, 0.88, 0.08), 7)
    add_body_part((0.09, 0.12, -0.07), (0.21, 0.52, 0.07), 8)
    add_body_part((0.08, 0.00, -0.18), (0.22, 0.12, 0.06), 9)
    # Arms (10..13)
    add_body_part((-0.42, 1.32, -0.07), (-0.19, 1.48, 0.07), 10)
    add_body_part((-0.62, 1.30, -0.06), (-0.42, 1.46, 0.06), 11)
    add_body_part((0.19, 1.32, -0.07), (0.42, 1.48, 0.07), 12)
    add_body_part((0.42, 1.30, -0.06), (0.62, 1.46, 0.06), 13)

    buffer_bytes = bytearray()
    def write_data(data, fmt):
        nonlocal buffer_bytes
        offset = len(buffer_bytes)
        packed = struct.pack(fmt, *data)
        buffer_bytes.extend(packed)
        return offset, len(packed)

    pos_offset, pos_len = write_data(vertices, f'<{len(vertices)}f')
    norm_offset, norm_len = write_data(normals, f'<{len(normals)}f')
    uv_offset, uv_len = write_data(uvs, f'<{len(uvs)}f')
    joint_offset, joint_len = write_data(joints, f'<{len(joints)}H')
    weight_offset, weight_len = write_data(weights, f'<{len(weights)}f')
    idx_offset, idx_len = write_data(indices, f'<{len(indices)}I')

    ibm_data = []
    for i in range(15):
        ibm_data.extend([1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0])
    ibm_offset, ibm_len = write_data(ibm_data, f'<{len(ibm_data)}f')

    def euler_to_quat(rx, ry, rz):
        cx, cy, cz = math.cos(rx*0.5), math.cos(ry*0.5), math.cos(rz*0.5)
        sx, sy, sz = math.sin(rx*0.5), math.sin(ry*0.5), math.sin(rz*0.5)
        return [sx*cy*cz - cx*sy*sz, cx*sy*cz + sx*cy*sz, cx*cy*sz - sx*sy*cz, cx*cy*cz + sx*sy*sz]

    accessors = [
        {"bufferView": 0, "byteOffset": pos_offset, "componentType": 5126, "count": len(vertices)//3, "type": "VEC3",
         "min": [min(vertices[0::3]), min(vertices[1::3]), min(vertices[2::3])],
         "max": [max(vertices[0::3]), max(vertices[1::3]), max(vertices[2::3])]},
        {"bufferView": 0, "byteOffset": norm_offset, "componentType": 5126, "count": len(normals)//3, "type": "VEC3"},
        {"bufferView": 0, "byteOffset": uv_offset, "componentType": 5126, "count": len(uvs)//2, "type": "VEC2"},
        {"bufferView": 0, "byteOffset": joint_offset, "componentType": 5123, "count": len(joints)//4, "type": "VEC4"},
        {"bufferView": 0, "byteOffset": weight_offset, "componentType": 5126, "count": len(weights)//4, "type": "VEC4"},
        {"bufferView": 0, "byteOffset": idx_offset, "componentType": 5125, "count": len(indices), "type": "SCALAR"},
        {"bufferView": 0, "byteOffset": ibm_offset, "componentType": 5126, "count": 15, "type": "MAT4"}
    ]

    num_frames = 20 if anim_target_name == "Idle" else 30 if anim_target_name in ["Walking", "Walk"] else 24 if anim_target_name in ["Running", "Run"] else 18
    dt = 1.0 / 30.0
    times = [i * dt for i in range(num_frames)]

    samplers = []
    channels = []

    for target_node, joint_id in [("UpperLeg_L", 4), ("UpperLeg_R", 7), ("UpperArm_L", 10), ("UpperArm_R", 12), ("Spine", 1)]:
        quats = []
        for frame in range(num_frames):
            t = frame / num_frames
            phase = t * math.pi * 2.0
            if target_node == "UpperLeg_L":
                rx = math.sin(phase) * (0.1 if "Idle" in anim_target_name else 0.6 if "Walk" in anim_target_name else 0.9 if "Run" in anim_target_name else 1.2)
                quats.append(euler_to_quat(rx, 0, 0))
            elif target_node == "UpperLeg_R":
                rx = math.sin(phase + math.pi) * (0.1 if "Idle" in anim_target_name else 0.6 if "Walk" in anim_target_name else 0.9 if "Run" in anim_target_name else 1.2)
                quats.append(euler_to_quat(rx, 0, 0))
            elif target_node == "UpperArm_L":
                rx = math.sin(phase + math.pi) * (0.05 if "Idle" in anim_target_name else 0.5 if "Walk" in anim_target_name else 0.8 if "Run" in anim_target_name else 1.1)
                quats.append(euler_to_quat(rx, 0, 0))
            elif target_node == "UpperArm_R":
                rx = math.sin(phase) * (0.05 if "Idle" in anim_target_name else 0.5 if "Walk" in anim_target_name else 0.8 if "Run" in anim_target_name else 1.1)
                quats.append(euler_to_quat(rx, 0, 0))
            else:
                rx = math.sin(phase * 2) * 0.03 + (0.2 if "Sprint" in anim_target_name else 0.1 if "Run" in anim_target_name else 0.0)
                quats.append(euler_to_quat(rx, 0, 0))

        t_off, t_len = write_data(times, f'<{len(times)}f')
        r_flat = []
        for q in quats:
            r_flat.extend(q)
        r_off, r_len = write_data(r_flat, f'<{len(r_flat)}f')

        acc_time_idx = len(accessors)
        accessors.append({"bufferView": 0, "byteOffset": t_off, "componentType": 5126, "count": len(times), "type": "SCALAR", "min": [times[0]], "max": [times[-1]]})
        acc_rot_idx = len(accessors)
        accessors.append({"bufferView": 0, "byteOffset": r_off, "componentType": 5126, "count": len(times), "type": "VEC4"})

        sampler_idx = len(samplers)
        samplers.append({"input": acc_time_idx, "output": acc_rot_idx, "interpolation": "LINEAR"})
        channels.append({"sampler": sampler_idx, "target": {"node": joint_id + 1, "path": "rotation"}})

    nodes = [
        {"name": "FemaleWarriorMesh", "mesh": 0, "skin": 0},
        {"name": "Hips", "translation": [0.0, 0.95, 0.0], "children": [2, 5, 8]},
        {"name": "Spine", "translation": [0.0, 0.25, 0.0], "children": [3]},
        {"name": "Chest", "translation": [0.0, 0.25, 0.0], "children": [4, 11, 13]},
        {"name": "Head", "translation": [0.0, 0.20, 0.0], "children": [15]},
        {"name": "UpperLeg_L", "translation": [-0.15, 0.0, 0.0], "children": [6]},
        {"name": "LowerLeg_L", "translation": [0.0, -0.40, 0.0], "children": [7]},
        {"name": "Foot_L", "translation": [0.0, -0.40, 0.0]},
        {"name": "UpperLeg_R", "translation": [0.15, 0.0, 0.0], "children": [9]},
        {"name": "LowerLeg_R", "translation": [0.0, -0.40, 0.0], "children": [10]},
        {"name": "Foot_R", "translation": [0.0, -0.40, 0.0]},
        {"name": "UpperArm_L", "translation": [-0.30, 0.0, 0.0], "children": [12]},
        {"name": "LowerArm_L", "translation": [-0.20, 0.0, 0.0]},
        {"name": "UpperArm_R", "translation": [0.30, 0.0, 0.0], "children": [14]},
        {"name": "LowerArm_R", "translation": [0.20, 0.0, 0.0]},
        {"name": "Hair", "translation": [0.0, -0.10, -0.15]}
    ]

    bin_filename = output_filename.replace(".gltf", ".bin")
    gltf_structure = {
        "asset": {"version": "2.0", "generator": "ZDEV-RPG Character Generator"},
        "scenes": [{"name": "Scene", "nodes": [0, 1]}],
        "scene": 0,
        "nodes": nodes,
        "materials": [{"name": "WarriorMaterial", "pbrMetallicRoughness": {"baseColorFactor": [0.8, 0.4, 0.3, 1.0], "metallicFactor": 0.4, "roughnessFactor": 0.5}}],
        "meshes": [{"name": "FemaleWarriorMesh", "primitives": [{"attributes": {"POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2, "JOINTS_0": 3, "WEIGHTS_0": 4}, "indices": 5, "material": 0}]}],
        "skins": [{"name": "Armature", "inverseBindMatrices": 6, "joints": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]}],
        "animations": [{"name": anim_target_name, "channels": channels, "samplers": samplers}],
        "accessors": accessors,
        "bufferViews": [{"buffer": 0, "byteOffset": 0, "byteLength": len(buffer_bytes)}],
        "buffers": [{"uri": os.path.basename(bin_filename), "byteLength": len(buffer_bytes)}]
    }

    out_gltf_path = os.path.join("ASSETS/mixamo", output_filename)
    out_bin_path = os.path.join("ASSETS/mixamo", bin_filename)

    with open(out_bin_path, "wb") as f:
        f.write(buffer_bytes)
    with open(out_gltf_path, "w") as f:
        json.dump(gltf_structure, f, indent=2)
    print(f"Generated {out_gltf_path}")

for anim in ["Idle", "Walking", "Running", "Sprint"]:
    create_single_anim_gltf(anim, f"{anim}.gltf")
