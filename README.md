# Godot 4.x Pixelated Water Shader

A pixel art style water shader for Godot 4.x, compatible with all rendering pipelines.
Features:
- Vertex waves
- Buoyancy system
- 2 types of lighting: Realistic and flat
- Foam overlay system

## Images

![ocean-beach-1](https://github.com/user-attachments/assets/b0f01c26-6a94-4d19-9c83-203ab489e7cc)

![oean-4](https://github.com/user-attachments/assets/613abd2c-3d9d-4634-980f-0fb424f303e3)

## Usage

### Vertex Waves

The water shader should be applied to a quad with a decent number of subdivisions.
#### Important Notes:
- Do not rotate the mesh the water is applied to, it will mess up the water_manager.gd calculations and the foam projection.
- To avoid jitter issues with the vertex waves, only move the water quad in increments that are multiples of your subdivision size. Usually moving it 1 unit at a time is sufficient.
- the **sync_time** uniform must be set in code every frame for the waves to move, WaterManager.gd does this already. If you don't need it to be synced correctly you can replace all instances of sync_time in the shader with TIME.

### Buoyancy

the water_manager.gd script calculates the water height given a position, then scripts like floating_box.gd or buoyancy.gd use that to calculate physics.

water_manager.gd contains a duplicate of the vertex wave calculations done in the shader so it can replicate the calculations, if you plan to chance those, make sure to also chance the duplicate in water_manager.gd.

#### water_manager.gd
##### Variables
- **enabled**: The state of the entire water system.
- **water_path**: Set to the water mesh node.
- **water_pos**: copy the position of the water mesh to this variable.
- **water_radius**: Set to the size of the water, any objects outside that area will never be considered to be in water. If the water extends infinitely, set to -1.

##### Functions:
- **calc_water_height(Vector3)**: receives a global position and returns the water height at that position. Uses bilinear interpolation to determine the height even if it the position is not on a vertex position
- **fast_water_height(Vector3)**: Same as above but does not use bilinear interpolation, samples the height 1 time instead of 4 but is much less accurate.

#### floating_box.gd
##### Variables
- **buoyancy_power**: This is multiplied by the gravity change that the rigidbody is given.

#### buoyancy.gd
##### Variables
- **buoyancy_power**: This is multiplied by the finished buoyancy amount.
- **damper**: Equivalent to the rigidbody "damp" but only applied to the buoyancy calculations
- **archimedes_force**: The overall force of the buoyancy, 4x the mass of the object is a good starting point
- **y_offset**: y offset of the center of gravity.
- **points_array**: The points to sample the buoyancy from
- **min_max_rotation**: Absolute value of the maximum rotation the object is allowed to do. IN RADIANS.
- **fast_mode**: Whether or not to use the water_manager.gd fast_water_height().

### Foam

The foam mask is intended to be used with a viewport texture from an orthographic camera that looks down at the water.
Usage steps:
1. create a SubViewport
2. place a Node3D inside the SubViewport and a Camera3D as a child of that Node3D.
3. Change the Camera3D to orthographic and set its size, ideally to a multiple of 2, ie: 64, 128, etc.
4. Set the Camera3D to only see a specific layer, name this layer "Foam"
5. Set the SubViewport size to a multiple of the Camera3D size.
6. In the water shader, set the foam_mask_size to the Camera3D size
7. Add in a mesh that is only visible on the layer you previously created and named "Foam", make sure that all other cameras cannot see this layer.
8. Add a material to that mesh that just outputs red.
9. The shader should read the red in the mask as a place where foam should show up.

### Vertex Coloring

- To allow the water to fade into fog, the water checks for the alpha of the mesh's vertex colors.
- Set the color it fades into with the sky_color uniform and then paint the vertex color alpha to set where it fades. 1 alpha is water, 0 alpha is sky.

## Info

"Cast Away Beach Diorama" (https://skfb.ly/opDrN) by Neil B is licensed under Creative Commons Attribution (http://creativecommons.org/licenses/by/4.0/).

Note: Not included in repository, for demonstrations only.

### Contact

If you have any questions you can start an issue or email me at contact@taillight.games
