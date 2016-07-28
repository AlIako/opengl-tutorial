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

package tests.alexisText;

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

class AlexisTextRenderer implements IMesh
{
    public var x: Float = 0;
    public var y: Float = 0;
    public var z: Float = 0;

    public var ui: Bool = false;

    private var r: Float = 0;
    private var g: Float = 0;
    private var b: Float = 0;

    inline static private var sizeOfFloat: Int = 4;
    inline static private var sizeOfShort: Int = 2;

    inline static private var positionAttributeCount: Int = 4;
    inline static private var texCoordAttributeCount: Int = 2;
    inline static private var colorAttributeCount: Int = 3;

    inline static private var positionAttributeIndex: Int = 0;
    inline static private var texCoordAttributeIndex: Int = 1;
    inline static private var colorAttributeIndex: Int = 2;

    private var indexCount: Int;

    private var vertexBufferData: Data;

    private var vertexBuffer: GLBuffer;
    private var indexBuffer: GLBuffer;

    private var textShader: Shader;
    private var texture: GLTexture;
    private var texturePath: String;

    private var mvpMatrix: Matrix4;

    private var textManager: TextManager;


    public function new (t: TextManager, font: String, red: Float, green: Float, blue: Float)
    {
        textManager = t;
        texturePath = font;
        r = red;
        g = green;
        b = blue;
    }

    public function initialize(): Void
    {
        createShader();
        createTexture();
        setBuffers(textManager.getVertexBufferValues(r, g, b), textManager.getIndicesValues());
    }

    private function createShader()
    {
        //http://stackoverflow.com/questions/21980947/replacement-for-gl-position-gl-modelviewprojectionmatrix-gl-vertex
        var vertexShader: String =
            "attribute highp vec4 a_Position;
            attribute highp vec2 a_TexCoord;
            attribute lowp  vec3 a_Color;

            uniform highp   mat4 uMVPMatrix;

            varying lowp    vec4 v_Color;
            varying highp   float v_TexCoordX;
            varying highp   float v_TexCoordY;

            void main()
            {
                gl_Position = a_Position * uMVPMatrix;

                v_Color = vec4(a_Color.x, a_Color.y, a_Color.z, 1.0);
                v_TexCoordX = a_TexCoord.s;
                v_TexCoordY = a_TexCoord.t;
            }
            ";
        var fragmentShader: String =
            "uniform    sampler2D s_Texture;

            varying lowp    vec4 v_Color;
            varying highp   float v_TexCoordX;
            varying highp   float v_TexCoordY;

            void main()
            {
                gl_FragColor = texture2D(s_Texture, vec2(v_TexCoordX, v_TexCoordY)) * v_Color;
            }
            ";
        textShader = new Shader();
        textShader.createShader(vertexShader, fragmentShader, ["a_Position", "a_TexCoord", "a_Color"],
        ["uMVPMatrix", "s_Texture"]);

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
        GL.texParameteri(GLDefines.TEXTURE_2D, GLDefines.TEXTURE_MIN_FILTER, GLDefines.LINEAR);

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

    //needed even if empty because of interface
    public function createBuffers(): Void
    {
    }

    private function setBuffers(?v: Array<Float>, ?ind: Array<Int>): Void
    {
        var vertexBufferValues: Array<Float> = new Array<Float>();
        if(v == null)
        {
        }
        else vertexBufferValues = v;

        //trace("vertexBufferValues: " + vertexBufferValues);
        /*trace("vecs: " + vecs);
        trace("uvs: " + uvs);
        trace("colors: " + colors);*/

        vertexBufferData = new Data(vertexBufferValues.length * sizeOfFloat);
        vertexBufferData.writeFloatArray(vertexBufferValues, DataType.DataTypeFloat32);
        vertexBufferData.offset = 0;

        vertexBuffer = GL.createBuffer();
        GL.bindBuffer(GLDefines.ARRAY_BUFFER, vertexBuffer);
        GL.bufferData(GLDefines.ARRAY_BUFFER, vertexBufferData, GLDefines.DYNAMIC_DRAW);
        GL.bindBuffer(GLDefines.ARRAY_BUFFER, GL.nullBuffer);

        //indices
        var indexBufferData: Data = null;
        indexCount = ind.length;
        indexBufferData = new Data(indexCount * sizeOfShort);
        indexBufferData.writeIntArray(ind, DataType.DataTypeUInt16);
        indexBufferData.offset = 0;
        //trace("indexBufferValues: " + ind);

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
        GL.enableVertexAttribArray(texCoordAttributeIndex); // 1
        GL.enableVertexAttribArray(colorAttributeIndex);    // 2

        GL.disableVertexAttribArray(3);
        GL.disableVertexAttribArray(4);
        GL.disableVertexAttribArray(5);
        GL.disableVertexAttribArray(6);
        GL.disableVertexAttribArray(7);

        var stride: Int = positionAttributeCount * sizeOfFloat + texCoordAttributeCount * sizeOfFloat + colorAttributeCount * sizeOfFloat;

        var attributeOffset: Int = 0;
        GL.vertexAttribPointer(positionAttributeIndex, positionAttributeCount, GLDefines.FLOAT, false, stride, attributeOffset);

        attributeOffset = positionAttributeCount * sizeOfFloat;
        GL.vertexAttribPointer(texCoordAttributeIndex, texCoordAttributeCount, GLDefines.FLOAT, false, stride, attributeOffset);

        attributeOffset = positionAttributeCount * sizeOfFloat + texCoordAttributeCount * sizeOfFloat;
        GL.vertexAttribPointer(colorAttributeIndex, colorAttributeCount, GLDefines.FLOAT, false, stride, attributeOffset);
    }

    public function unbindMesh(): Void
    {
        GL.bindBuffer(GLDefines.ARRAY_BUFFER, GL.nullBuffer);
        GL.bindBuffer(GLDefines.ELEMENT_ARRAY_BUFFER, GL.nullBuffer);
    }

    public function setMVP(mvp: Matrix4): Void
    {
        mvpMatrix = mvp;
        if(ui)
            mvpMatrix.setIdentity();
    }

    public function draw(): Void
    {
        var useShader: Bool = true;
        if(useShader && texturePath != null)
        {
            GL.useProgram(textShader.shaderProgram);

            //https://www.opengl.org/sdk/docs/tutorials/ClockworkCoders/uniform.php
            var mvpMatIdx = GL.getUniformLocation(textShader.shaderProgram, "uMVPMatrix");
            GL.uniformMatrix4fv(mvpMatIdx, 1, false, mvpMatrix.data);

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
        textShader.destroyShader();
    }
}
