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

import haxe.ds.Vector;
import Std;

class TextManager {
    private var textShader: Shader;
    private var texture: GLTexture;

    inline static private var sizeOfFloat: Int = 4;
    inline static private var sizeOfShort: Int = 2;

    inline static private var positionAttributeCount: Int = 4;
    inline static private var texCoordAttributeCount: Int = 2;
    inline static private var colorAttributeCount: Int = 4;

    inline static private var positionAttributeIndex: Int = 0;
    inline static private var texCoordAttributeIndex: Int = 1;
    inline static private var colorAttributeIndex: Int = 2;

    private var indexCount: Int;

    private static var RI_TEXT_UV_BOX_WIDTH: Float = 0.125;
    private static var RI_TEXT_WIDTH: Float = 32.0;
    private static var RI_TEXT_SPACESIZE: Float = 20;

    private var textureBuffer: GLBuffer;
    private var colorBuffer: GLBuffer;
    private var drawListBuffer: GLBuffer;

    private var vecs: Vector<Float>;
    private var uvs: Vector<Float>;
    private var indices: Vector<Int>;
    private var colors: Vector<Float>;

    private var index_vecs: Int;
    private var index_indices: Int;
    private var index_uvs: Int;
    private var index_colors: Int;

    private var texturenr: Int;

    private var uniformscale: Float;

    public static var l_size: Array<Int> = [36,29,30,34,25,25,34,33,
                                            11,20,31,24,48,35,39,29,
                                            42,31,27,31,34,35,46,35,
                                            31,27,30,26,28,26,31,28,
                                            28,28,29,29,14,24,30,18,
                                            26,14,14,14,25,28,31,0,
                                            0,38,39,12,36,34,0,0,
                                            0,38,0,0,0,0,0,0];

    public var txtcollection: Array<TextObject>;

    private var scale: Float = 1000.0;

    public function new()
    {
        // Create our container
        txtcollection = new Array<TextObject>();

        // Create the arrays
        vecs = new Vector<Float>(3 * 10);
        colors = new Vector<Float>(4 * 10);
        uvs = new Vector<Float>(2 * 10);
        indices = new Vector<Int>(10);

        // init as 0 as default
        texturenr = 0;
    }

    public function getVertexBufferValues(red: Float, green: Float, blue: Float): Array<Float>
    {
        var vertexBufferValues: Array<Float> = new Array<Float>();
        var iter: Int = 0;
        while (iter + 2 < vecs.length )
        {
            //position
            vertexBufferValues = vertexBufferValues.concat([vecs[3*iter]/scale, vecs[3*iter+1]/scale, vecs[3*iter+2] * 0, 1.0]);

            //texture
            vertexBufferValues = vertexBufferValues.concat([uvs[2*iter], uvs[2*iter+1]]);

            //color
            //vertexBufferValues = vertexBufferValues.concat([colors[3*iter], colors[3*iter+1], colors[3*iter+2]]);
            vertexBufferValues = vertexBufferValues.concat([red, green, blue]);
            iter ++;
        }
        /*trace("vecs: " + vecs);
        trace("uvs: " + uvs);
        trace("colors: " + colors);*/
        return vertexBufferValues;
    }
    public function getIndicesValues(): Array<Int>
    {
        return indices.toArray();
    }


    public function addText(obj: TextObject): Void
    {
        // Add text object to our collection
        txtcollection.push(obj);
    }

    public function setTextureID(val: Int): Void
    {
        texturenr = val;
    }

    public function AddCharRenderInformation(vec: Vector<Float>, cs: Vector<Float>, uv: Vector<Float>, indi: Array<Int>): Void
    {
        // We need a base value because the object has indices related to
        // that object and not to this collection so basicly we need to
        // translate the indices to align with the vertexlocation in ou
        // vecs array of vectors.
        var base: Int = Std.int((index_vecs / 3));

        // We should add the vec, translating the indices to our saved vector
        for(i in 0...vec.length)
        {
            vecs[index_vecs] = vec[i];
            index_vecs++;
        }

        // We should add the colors.
        for(i in 0...cs.length)
        {
            colors[index_colors] = cs[i];
            index_colors++;
        }

        // We should add the uvs
        for(i in 0...uv.length)
        {
            uvs[index_uvs] = uv[i];
            index_uvs++;
        }

        // We handle the indices
        for(j in 0...indi.length)
        {
            indices[index_indices] = Std.int((base + indi[j]));
            index_indices++;
        }
    }

    public function PrepareDrawInfo(): Void
    {
        // Reset the indices.
        index_vecs = 0;
        index_indices = 0;
        index_uvs = 0;
        index_colors = 0;

        // Get the total amount of characters
        var charcount: Int = 0;
        for (txt in txtcollection) {
            if(txt != null)
            {
                if(!(txt.text == null))
                {
                    charcount += (txt.text).length;
                }
            }
        }

        // Create the arrays we need with the correct size.
        vecs = null;
        colors = null;
        uvs = null;
        indices = null;

        vecs = new Vector<Float>(charcount * 12);
        colors = new Vector<Float>(charcount * 16);
        uvs = new Vector<Float>(charcount * 8);
        indices = new Vector<Int>(charcount * 6);

    }

    public function PrepareDraw(): Void
    {
        // Setup all the arrays
        PrepareDrawInfo();

        // Using the iterator protects for problems with concurrency
        for(i in txtcollection)
        {
            var txt: TextObject = i;
            if(txt != null)
            {
                convertTextToTriangleInfo(txt);
            }
        }
    }


    private function convertCharToIndex(c_val: Int): Int
    {
        var indx: Int = -1;

        // Retrieve the index
        if(c_val > 64 && c_val < 91) // A-Z
            indx = c_val - 65;
        else if(c_val > 96 && c_val < 123) // a-z
            indx = c_val - 97;
        else if(c_val > 47 && c_val < 58) // 0-9
            indx = c_val - 48 + 26;
        else if(c_val == 43) // +
            indx = 38;
        else if(c_val == 45) // -
            indx = 39;
        else if(c_val == 33) // !
            indx = 36;
        else if(c_val == 63) // ?
            indx = 37;
        else if(c_val == 61) // =
            indx = 40;
        else if(c_val == 58) // :
            indx = 41;
        else if(c_val == 46) // .
            indx = 42;
        else if(c_val == 44) // ,
            indx = 43;
        else if(c_val == 42) // *
            indx = 44;
        else if(c_val == 36) // $
            indx = 45;

        return indx;
    }

    private function convertTextToTriangleInfo(val: TextObject): Void
    {
        // Get attributes from text object
        var x: Float = val.x;
        var y: Float = val.y;
        var text: String = val.text;

        var offsetX: Float = 0.0;

        //calculate width
        if(val.alignCenter)
        {
            for(j in 0...text.length)
            {
                // get ascii value
                var c: Null<Int> = text.charCodeAt(j);
                
                var c_val: Int = 0;
                if(c != null)
                    c_val = c;

                var indx: Int = convertCharToIndex(c_val);
                if(indx == -1) {
                    // unknown character, we will add a space for it to be save.
                    offsetX += ((RI_TEXT_SPACESIZE) * uniformscale);
                    continue;
                }
                offsetX += ((l_size[indx] / 2)  * uniformscale);
            }
            offsetX *= -1.0/2;
        }
        // Create
        for(j in 0...text.length)
        {
            // get ascii value
            var c: Null<Int> = text.charCodeAt(j);
            var c_val: Int = 0;
            if(c != null)
            {
                c_val = c;
            }

            var indx: Int = convertCharToIndex(c_val);

            if(indx == -1) {
                // unknown character, we will add a space for it to be save.
                x += ((RI_TEXT_SPACESIZE) * uniformscale);
                continue;
            }

            // Calculate the uv parts
            var row: Int = Std.int(indx / 8);
            var col: Int = indx % 8;

            var v: Float = row * RI_TEXT_UV_BOX_WIDTH;
            var v2: Float = v + RI_TEXT_UV_BOX_WIDTH;
            var u: Float = col * RI_TEXT_UV_BOX_WIDTH;
            var u2: Float = u + RI_TEXT_UV_BOX_WIDTH;

            // Creating the triangle information
            var vec: Vector<Float> = new Vector<Float>(12);
            var uv: Vector<Float> = new Vector<Float>(8);
            var colors: Vector<Float> = new Vector<Float>(16);

            vec[0] = x + offsetX;
            vec[1] = y + (RI_TEXT_WIDTH * uniformscale);
            vec[2] = 0.99;
            vec[3] = x + offsetX;
            vec[4] = y;
            vec[5] = 0.99;
            vec[6] = x + (RI_TEXT_WIDTH * uniformscale) + offsetX;
            vec[7] = y;
            vec[8] = 0.99;
            vec[9] = x + (RI_TEXT_WIDTH * uniformscale) + offsetX;
            vec[10] = y + (RI_TEXT_WIDTH * uniformscale);
            vec[11] = 0.99;

            colors = Vector.fromArrayCopy([val.color.get_x(), val.color.get_y(), val.color.get_z(), 1.0,
            val.color.get_x(), val.color.get_y(), val.color.get_z(), 1.0,
            val.color.get_x(), val.color.get_y(), val.color.get_z(), 1.0,
            val.color.get_x(), val.color.get_y(), val.color.get_z(), 1.0]);

            // 0.001f = texture bleeding hack/fix
            uv[0] = u + 0.001;
            uv[1] = v + 0.001;
            uv[2] = u + 0.001;
            uv[3] = v2 - 0.001;
            uv[4] = u2 - 0.001;
            uv[5] = v2 - 0.001;
            uv[6] = u2 - 0.001;
            uv[7] = v + 0.001;

            //trace("uv debug: " + uv);

            var inds: Array<Int> = [0, 1, 2, 0, 2, 3];

            // Add our triangle information to our collection for 1 render call.
            AddCharRenderInformation(vec, colors, uv, inds);

            // Calculate the new position
            x += ((l_size[indx] / 2)  * uniformscale);

        }
    }

    public function getUniformscale(): Float {
        return uniformscale;
    }

    public function setUniformscale(u: Float): Void {
        uniformscale = u;
    }
}
