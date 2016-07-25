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

import gl.GLDefines;
import types.DataType;
import gl.GL;
import types.Data;
import tests.utils.IMesh;
import types.Vector3;
import tests.utils.AssetLoader;
import tests.utils.Bitmap;
import tests.utils.ImageDecoder;
import tests.utils.Shader;
import duellkit.DuellKit;

import types.Matrix3;
import types.Matrix3Matrix4Tools;
import types.Matrix4;
import types.Matrix4Tools;

using types.Matrix4Tools;
using types.Matrix3Tools;
using types.Matrix3Matrix4Tools;
using types.Matrix3DataTools;

class AlexisObjMesh implements IMesh
{
    inline static private var sizeOfFloat: Int = 4;
    inline static private var sizeOfShort: Int = 2;

    inline static private var positionAttributeCount: Int = 4;
    inline static private var normalAttributeCount: Int = 3;
    inline static private var texCoordAttributeCount: Int = 2;

    inline static private var positionAttributeIndex: Int = 0;
    inline static private var normalAttributeIndex: Int = 1;
    inline static private var texCoordAttributeIndex: Int = 2;

    private var indexCount: Int;

    private var vertexBufferData: Data;

    private var vertexBuffer: GLBuffer;
    private var indexBuffer: GLBuffer;

    private var normalMatrix3Data: Data;

    private var ambientColor: Vector3;
    private var lightColor: Vector3;
    private var lightDirection: Vector3;
    private var lightPosition: Vector3;

    private var faces: Array<Face>;
    private var vertexesX: Array<Float>;
    private var vertexesY: Array<Float>;
    private var texturePath: String;

    private var textureShader: Shader;
    private var texture: GLTexture;

    private var mvpMatrix: Matrix4;

    private var _scale: Float;

    public function new ()
    {
        _scale = 1;
    }

    public function loadMesh(fileName: String, scale: Float): Bool
    {
        _scale = scale;

        //load the vertexes from a .obj file with MeshLoader
        MeshLoader.load(fileName);
        faces = MeshLoader.getFaces().copy();

        //get Vertexes from MeshLoader and separate them in two (X and Y)
        var vertexesTemp = MeshLoader.getVertexes().copy();
        vertexesX = new Array<Float>();
        vertexesY = new Array<Float>();
        for (i in 0...vertexesTemp.length)
        {
            vertexesX.push(vertexesTemp[i].get_x());
            vertexesY.push(vertexesTemp[i].get_y());
        }

        //find texture path with identical name as the mesh
        texturePath = new String(MeshLoader.getTexturePath(fileName));
        if(texturePath != null)
        {
            createShader();
            createTexture();
        }

        return faces != null;
    }

    private function createShader()
    {
        //http://stackoverflow.com/questions/21980947/replacement-for-gl-position-gl-modelviewprojectionmatrix-gl-vertex

        //Vertex Shader for projection, texturing and lighting
        var vertexShader: String =
            "attribute highp vec4 a_Position;
            attribute lowp  vec3 a_Normal;
            attribute highp vec2 a_TexCoord;

            uniform highp   mat4 u_MVPMatrix;
            uniform highp   mat3 u_NormalMatrix;

            uniform   highp vec3 u_AmbientColorVector;
            uniform   highp vec3 u_LightColorVector;
            uniform   highp vec3 u_LightDirection;

            varying lowp    vec4 v_Color;
            varying highp   float v_TexCoordX;
            varying highp   float v_TexCoordY;
            varying lowp  vec3 v_Lighting;

            void main()
            {
                gl_Position = a_Position * u_MVPMatrix;

                v_Color = vec4(1.0, 1.0, 1.0, 1.0);
                v_TexCoordX = a_TexCoord.s;
                v_TexCoordY = 1.0 - a_TexCoord.t;

                vec3 eyeNormal = normalize(u_NormalMatrix * a_Normal);
                float directional = max(0.0, dot(eyeNormal, normalize(u_LightDirection)));

                v_Lighting = u_AmbientColorVector + (u_LightColorVector * directional);
            }
            ";

        //fragment shader for texturing and lighting
        var fragmentShader: String =
            "uniform    sampler2D s_Texture;

            varying lowp    vec4 v_Color;
            varying highp   float v_TexCoordX;
            varying highp   float v_TexCoordY;
            varying lowp    vec3 v_Lighting;

            void main()
            {
                gl_FragColor = texture2D(s_Texture, vec2(v_TexCoordX, v_TexCoordY)) * v_Color;
                gl_FragColor[0] = gl_FragColor[0] * v_Lighting[0];
                gl_FragColor[1] = gl_FragColor[1] * v_Lighting[1];
                gl_FragColor[2] = gl_FragColor[2] * v_Lighting[2];
            }
            ";
        textureShader = new Shader();
        textureShader.createShader(vertexShader, fragmentShader, ["a_Position", "a_Normal", "a_TexCoord"],
        ["u_MVPMatrix", "u_NormalMatrix", "u_AmbientColorVector", "u_LightColorVector", "u_LightDirection", "s_Texture"]);

    }

    private function createTexture(): Void
    {
        var imageData: Data = AssetLoader.getDataFromFile(texturePath);
        var bitmap: Bitmap = ImageDecoder.decodePNG(imageData);

        /// Create, configure and upload opengl texture
        texture = GL.createTexture();
        GL.bindTexture(GLDefines.TEXTURE_2D, texture);

        // Configure Filtering Mode
        GL.texParameteri(GLDefines.TEXTURE_2D, GLDefines.TEXTURE_MAG_FILTER, GLDefines.NEAREST);
        GL.texParameteri(GLDefines.TEXTURE_2D, GLDefines.TEXTURE_MIN_FILTER, GLDefines.NEAREST);

        // Configure wrapping
        GL.texParameteri(GLDefines.TEXTURE_2D, GLDefines.TEXTURE_WRAP_S, GLDefines.REPEAT);
        GL.texParameteri(GLDefines.TEXTURE_2D, GLDefines.TEXTURE_WRAP_T, GLDefines.REPEAT);

        // Copy data to gpu memory
        switch (bitmap.components)
        {
            case 3:
                {
                    GL.pixelStorei(GLDefines.UNPACK_ALIGNMENT, 2);
                    GL.texImage2D(GLDefines.TEXTURE_2D, 0, GLDefines.RGB, bitmap.width, bitmap.height, 0, GLDefines.RGB, GLDefines.UNSIGNED_SHORT_5_6_5, bitmap.data);
                }
            case 4:
                {
                    GL.pixelStorei(GLDefines.UNPACK_ALIGNMENT, 4);
                    GL.texImage2D(GLDefines.TEXTURE_2D, 0, GLDefines.RGBA, bitmap.width, bitmap.height, 0, GLDefines.RGBA, GLDefines.UNSIGNED_BYTE, bitmap.data);
                }
            case 1:
                {
                    GL.pixelStorei(GLDefines.UNPACK_ALIGNMENT, 1);
                    GL.texImage2D(GLDefines.TEXTURE_2D, 0, GLDefines.ALPHA, bitmap.width, bitmap.height, 0, GLDefines.ALPHA, GLDefines.UNSIGNED_BYTE, bitmap.data);
                }
            default: throw("Unsupported number of components");
        }

        GL.bindTexture(GLDefines.TEXTURE_2D, GL.nullTexture);
    }

    public function createBuffers(): Void
    {
        //create the vertex buffer array with the faces loaded from the .obj
        var vertexBufferValues: Array<Float> = new Array<Float>();
        for (i in 0...faces.length)
            vertexBufferValues = vertexBufferValues.concat(faces[i].getVertexBufferValues(_scale));

        vertexBufferData = new Data(vertexBufferValues.length * sizeOfFloat);
        vertexBufferData.writeFloatArray(vertexBufferValues, DataType.DataTypeFloat32);
        vertexBufferData.offset = 0;

        vertexBuffer = GL.createBuffer();
        GL.bindBuffer(GLDefines.ARRAY_BUFFER, vertexBuffer);
        GL.bufferData(GLDefines.ARRAY_BUFFER, vertexBufferData, GLDefines.DYNAMIC_DRAW);
        GL.bindBuffer(GLDefines.ARRAY_BUFFER, GL.nullBuffer);

        //The vertex Buffer defines the points of the mesh. But it is not enough to have points, you
        //need to know which ones are connected. For that we use the index Buffer.
        //So we actually define the faces. A face is a triangle, so 3 points. We add 3 points
        //per 3 points to the index Buffer arrays which give us our faces.
        var indexBufferValues: Array<Int> = new Array<Int>();
        for (i in 0...faces.length)
            indexBufferValues = indexBufferValues.concat([ i*3,  i*3+1,  i*3+2]);

        indexCount = indexBufferValues.length;
        var indexBufferData: Data = new Data(indexCount * sizeOfShort);
        indexBufferData.writeIntArray(indexBufferValues, DataType.DataTypeUInt16);
        indexBufferData.offset = 0;

        indexBuffer = GL.createBuffer();
        GL.bindBuffer(GLDefines.ELEMENT_ARRAY_BUFFER, indexBuffer);
        GL.bufferData(GLDefines.ELEMENT_ARRAY_BUFFER, indexBufferData, GLDefines.STATIC_DRAW);
        GL.bindBuffer(GLDefines.ELEMENT_ARRAY_BUFFER, GL.nullBuffer);

    }

    public function destroyBuffers(): Void
    {
        GL.deleteBuffer(indexBuffer);
        GL.deleteBuffer(vertexBuffer);
    }

    public function bindMesh(): Void
    {
        GL.bindBuffer(GLDefines.ARRAY_BUFFER, vertexBuffer);
        GL.bindBuffer(GLDefines.ELEMENT_ARRAY_BUFFER, indexBuffer);

        //http://stackoverflow.com/questions/8704801/glvertexattribpointer-clarification?rq=1

        GL.enableVertexAttribArray(positionAttributeIndex); // 0
        GL.enableVertexAttribArray(normalAttributeIndex);    // 1
        GL.enableVertexAttribArray(texCoordAttributeIndex); // 2

        GL.disableVertexAttribArray(3);
        GL.disableVertexAttribArray(4);
        GL.disableVertexAttribArray(5);
        GL.disableVertexAttribArray(6);
        GL.disableVertexAttribArray(7);

        var stride: Int = positionAttributeCount * sizeOfFloat + normalAttributeCount * sizeOfFloat + texCoordAttributeCount * sizeOfFloat;

        var attributeOffset: Int = 0;
        GL.vertexAttribPointer(positionAttributeIndex, positionAttributeCount, GLDefines.FLOAT, false, stride, attributeOffset);

        attributeOffset = positionAttributeCount * sizeOfFloat;
        GL.vertexAttribPointer(normalAttributeIndex, normalAttributeCount, GLDefines.FLOAT, false, stride, attributeOffset);

        attributeOffset = positionAttributeCount * sizeOfFloat + normalAttributeCount * sizeOfFloat;
        GL.vertexAttribPointer(texCoordAttributeIndex, texCoordAttributeCount, GLDefines.FLOAT, false, stride, attributeOffset);
    }

    public function unbindMesh(): Void
    {
        GL.bindBuffer(GLDefines.ARRAY_BUFFER, GL.nullBuffer);
        GL.bindBuffer(GLDefines.ELEMENT_ARRAY_BUFFER, GL.nullBuffer);
    }

    public function setMVP(mvp: Matrix4): Void
    {
        mvpMatrix = mvp;
    }

    public function setLightVectors(m: Data, a: Vector3, lc: Vector3, ld: Vector3, lp: Vector3): Void
    {
        normalMatrix3Data = m;
        ambientColor = a;
        lightColor = lc;
        lightDirection = ld;
        lightPosition = lp;
    }

    public function draw(): Void
    {
        var useShader: Bool = true;
        if(useShader && texturePath != null)
        {
            GL.useProgram(textureShader.shaderProgram);

            //https://www.opengl.org/sdk/docs/tutorials/ClockworkCoders/uniform.php
            var mvpMatIdx = GL.getUniformLocation(textureShader.shaderProgram, "u_MVPMatrix");
            GL.uniformMatrix4fv(mvpMatIdx, 1, false, mvpMatrix.data);

            var mvpMat3Idx = GL.getUniformLocation(textureShader.shaderProgram, "u_NormalMatrix");
            GL.uniformMatrix3fv(mvpMat3Idx, 1, false, normalMatrix3Data);

            var ambientColorIdx = GL.getUniformLocation(textureShader.shaderProgram, "u_AmbientColorVector");
            GL.uniform3fv(ambientColorIdx, 1, ambientColor.data);

            var lightColorIdx = GL.getUniformLocation(textureShader.shaderProgram, "u_LightColorVector");
            GL.uniform3fv(lightColorIdx, 1, lightColor.data);

            var lightDirectionIdx = GL.getUniformLocation(textureShader.shaderProgram, "u_LightDirection");
            GL.uniform3fv(lightDirectionIdx, 1, lightDirection.data);


            GL.activeTexture(GLDefines.TEXTURE0);
            GL.bindTexture(GLDefines.TEXTURE_2D, texture);
        }

        bindMesh();

        var indexOffset: Int = 0;
        GL.drawElements(GLDefines.TRIANGLES, indexCount, GLDefines.UNSIGNED_SHORT, indexOffset);

        unbindMesh();

        GL.bindTexture(GLDefines.TEXTURE_2D, GL.nullTexture);
    }

    // Destroy your created OpenGL objectes
    public function onDestroy(): Void
    {
        GL.deleteTexture(texture);
        textureShader.destroyShader();
    }
}
