{GameObject} = require './gameobject'
{mat2, mat3, mat4, vec2, vec3, vec4, quat} = require 'gl-matrix'

ZERO_MAT4 = new(Float32Array)(16)
VECTOR_X = new Float32Array [1,0,0]
VECTOR_Y = new Float32Array [0,1,0]


class Camera extends GameObject

    type = 'CAMERA'

    constructor: (@context, field_of_view=30.0, aspect_ratio=1, near_plane=0.1, far_plane=10000.0)->
        super @context
        @near_plane = near_plane
        @far_plane = far_plane
        @field_of_view = field_of_view * Math.PI / 180.0
        @aspect_ratio = aspect_ratio
        @cam_type = 'PERSP'
        @sensor_fit = 'AUTO'
        @projection_matrix = new Float32Array 16
        @projection_matrix_inv = new Float32Array 16
        @world_to_screen_matrix = new Float32Array 16
        @cull_left = new Float32Array 3
        @cull_bottom = new Float32Array 3
        @recalculate_projection()

    #Avoid physical lamps and cameras
    instance_physics: ->

    get_ray_direction: (x, y)->
        # Assumes screen coordinates (0 to 1)
        v = vec3.create()
        v[0] = x*2-1
        v[1] = y*-2+1
        v[2] = 1
        vec3.transformMat4 v, v, @projection_matrix_inv
        vec3.transformQuat v, v, @get_world_rotation()
        return v

    get_ray_direction_local: (x, y)->
        # Assumes screen coordinates (0 to 1)
        v = vec3.create()
        v[0] = x*2-1
        v[1] = y*-2+1
        v[2] = 1
        vec3.transformMat4 v, v, @projection_matrix_inv
        vec3.transformQuat v, v, @rotation
        return v

    recalculate_projection: ->

        near_plane = @near_plane
        far_plane = @far_plane
        sensor_fit = @sensor_fit
        if @cam_type == 'PERSP'
            half_size = near_plane * Math.tan(@field_of_view/2)
        else if @cam_type == 'ORTHO'
            half_size = @ortho_scale/2
        else
            raise "Camera.cam_type must be PERSP or ORTHO."

        if sensor_fit == 'AUTO'
            if @aspect_ratio > 1
                sensor_fit = 'HORIZONTAL'
            else
                sensor_fit = 'VERTICAL'
        if sensor_fit == 'HORIZONTAL'
            right = half_size
            top = right / @aspect_ratio
        else if sensor_fit == 'VERTICAL'
            top = half_size
            right = top * @aspect_ratio
        else
            raise "Camera.sensor_fit must be AUTO, HORIZONTAL or VERTICAL."

        bottom = -top
        left = -right

        pm = @projection_matrix
        a = (right + left) / (right - left)
        b = (top + bottom) / (top - bottom)
        c = -(far_plane + near_plane) / (far_plane - near_plane)
        if @cam_type == 'PERSP'
            d = -(2 * far_plane * near_plane) / (far_plane - near_plane)
            x = (2 * near_plane) / (right - left)
            y = (2 * near_plane) / (top - bottom)
            # x, 0, 0, 0,
            # 0, y, 0, 0,
            # a, b, c, -1,
            # 0, 0, d, 0
            pm.set ZERO_MAT4
            pm[0] = x
            pm[5] = y
            pm[8] = a
            pm[9] = b
            pm[10] = c
            pm[11] = -1
            pm[14] = d
            mat4.invert @projection_matrix_inv, @projection_matrix
            v = @cull_left
            v[0] = -1
            v[1] = 0
            v[2] = 1
            vec3.transformMat4 v, v, @projection_matrix_inv
            vec3.cross v, v, VECTOR_Y
            vec3.normalize v, v
            v = @cull_bottom
            v[0] = 0
            v[1] = -1
            v[2] = 1
            vec3.transformMat4 v, v, @projection_matrix_inv
            vec3.cross v, VECTOR_X, v
            vec3.normalize v, v
        else
            d = -2 / (far_plane - near_plane)
            x = 2 / (right - left)
            y = 2 / (top - bottom)
            #  x, 0, 0, 0,
            #  0, y, 0, 0,
            #  0, 0, d, 0,
            # -a,-b, c, 1
            pm.set ZERO_MAT4
            pm[0] = x
            pm[5] = y
            pm[10] = d
            pm[12] = -a
            pm[13] = -b
            pm[14] = c
            pm[15] = 1
            mat4.invert @projection_matrix_inv, @projection_matrix
            console.error "TODO: frustum culling for ortho!"

module.exports = {Camera}
