/*
 * Copyright (c) 2011-2015, 2time.net | Sven Otto
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package tests.alexisObj;

import types.Vector3;

class Face
{
    private var vertices: Array<Vector3>;
    private var vertexes: Array<Vector3>;
    private var normals: Array<Vector3>;

    private var color: Vector3;

    private var initialized : Bool = false;

    public function new( v1: Vector3, v2: Vector3, v3: Vector3,
                                vt1: Vector3, vt2: Vector3, vt3: Vector3,
                                vn1: Vector3, vn2: Vector3, vn3: Vector3): Void
    {
        color = new Vector3();
        color.setXYZ(0, 0, 1);

        vertices = new Array<Vector3>();
        vertexes = new Array<Vector3>();
        normals = new Array<Vector3>();

        vertices.push(v1);
        vertices.push(v2);
        vertices.push(v3);

        vertexes.push(vt1);
        vertexes.push(vt2);
        vertexes.push(vt3);

        normals.push(vn1);
        normals.push(vn2);
        normals.push(vn3);
    }

    public function getVertexBufferValues(?scale: Float): Array<Float>
    {
        var _scale: Float = 1;
        if(scale != null)
            _scale = scale;

        var vertexBufferValues: Array<Float> = new Array<Float>();
        for (i in 0...3)
        {
            vertexBufferValues = vertexBufferValues.concat([vertices[i].get_x() * _scale,vertices[i].get_y() * _scale,vertices[i].get_z() * _scale,1.0, //x y z w
                                            normals[i].get_x(),normals[i].get_y(),normals[i].get_z(), //nx ny nz
                                            vertexes[i].get_x(),vertexes[i].get_y()]); //tx ty
        }

        return vertexBufferValues;
    }

    public function setColor(r: Float, g: Float, b: Float): Void
    {
        color.set_x(r);
        color.set_y(g);
        color.set_z(b);
    }
}
