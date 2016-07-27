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

import duellkit.DuellKit;
import gl.GL;
import gl.GLDefines;
import gl.GLContext;
import types.Data;
import types.Vector3;
import types.Matrix3;
import types.Matrix3Matrix4Tools;
import types.Matrix4;
import types.Matrix4Tools;
import tests.utils.AssetLoader;
import tests.utils.Shader;
import tests.alexisObj.AlexisObjMesh;
import Std;

using types.Matrix4Tools;
using types.Matrix3Tools;
using types.Matrix3Matrix4Tools;
using types.Matrix3DataTools;

class AlexisText extends OpenGLTest
{
    inline static private var floatSize: Int = 4;
    inline static private var matrix3Size: Int = 9;

    private var normalMatrix3: Matrix3;

    private var normalMatrix3Data: Data;

    private var ambientColor: Vector3;
    private var lightColor: Vector3;
    private var lightDirection: Vector3;
    private var lightPosition: Vector3;

    private var cameraPosition: Vector3;
    private var zeroPosition: Vector3;
    private var upDirection: Vector3;

    private var modelMatrix: Matrix4;
    private var viewMatrix: Matrix4;
    private var projection: Matrix4;

    private var mvpObj: Matrix4;
    private var mvpText: Matrix4;

    private var alexisBackground: AlexisBackground;
    private var alexisTextRenderer: AlexisTextRenderer;
    private var alexisTextRenderer2: AlexisTextRenderer;
    private var textManager: TextManager;
    private var textManager2: TextManager;

    // Create OpenGL objectes (Shaders, Buffers, Textures) here
    override private function onCreate(): Void
    {
        super.onCreate();

        configureOpenGLState();
        createMesh();
    }

    // Destroy your created OpenGL objectes
    override public function onDestroy(): Void
    {
        destroyMesh();
        super.onDestroy();
    }

    private function configureOpenGLState(): Void
    {
        GL.clearColor(0.0, 0.0, 0.0, 1.0);
        GL.enable(GLDefines.DEPTH_TEST);
        GL.depthMask(true);

        normalMatrix3Data = new Data(matrix3Size * floatSize);

        normalMatrix3 = new Matrix3();

        ambientColor = new Vector3();
        ambientColor.setXYZ(0.0, 0.0, 0.0);

        lightColor = new Vector3();
        lightColor.setXYZ(1.0, 1.0, 1.0);

        lightDirection = new Vector3();

        lightPosition = new Vector3();
        lightPosition.setXYZ(0.0, 0.0, 2.0);

        cameraPosition = new Vector3();
        cameraPosition.setXYZ(0.0, -4.0, 4.0);

        zeroPosition = new Vector3();

        upDirection = new Vector3();
        upDirection.z = 1.0;

        modelMatrix = new Matrix4();
        modelMatrix.setIdentity();

        viewMatrix = new Matrix4();
        viewMatrix.setIdentity();

        var aspect: Float = DuellKit.instance().screenWidth / DuellKit.instance().screenHeight;

        projection = new Matrix4();
        projection.setPerspectiveFov(Math.PI * 0.3, aspect, 0.1, 2000.0);

        mvpObj = new Matrix4();
        mvpText = new Matrix4();
    }

    private function createMesh()
    {
        GL.frontFace(GLDefines.CCW);
        GL.disable(GLDefines.CULL_FACE);

        //stars background
        alexisBackground = new AlexisBackground();

        //text manager
        var center: Bool = true;
        textManager = new TextManager();
        textManager.setTextureID(1);
        textManager.setUniformscale(5);
        textManager.addText(new TextObject("Hello world!", 0, 0, center));
        textManager.addText(new TextObject("This is a bitmapfont text!", 0, -150, center));
        textManager.addText(new TextObject("Lorem ipsum dolor sit amet,", 0, -600, center));
        textManager.addText(new TextObject("consectetuer adipiscing elit.", 0, -750, center));
        textManager.addText(new TextObject("Cum sociis natoque penatibus et", 0, -900, center));
        textManager.addText(new TextObject("magnis dis parturient montes,", 0, -1050, center));
        textManager.addText(new TextObject("nascetur ridiculus mus.", 0, -1200, center));
        textManager.PrepareDraw();

        //text renderer
        alexisTextRenderer = new AlexisTextRenderer(textManager, "font/font.png", 1.0, 1.0, 0.0);
        alexisTextRenderer.initialize();
        alexisTextRenderer.y = -3;
        alexisTextRenderer.z = 2;

        var screenwidth = GLContext.getMainContext().contextWidth;
        var screenheight = GLContext.getMainContext().contextHeight;

        //text manager2
        textManager2 = new TextManager();
        textManager2.setTextureID(1);
        textManager2.setUniformscale(3);
        textManager2.addText(new TextObject("UI renderer",
            -screenwidth / 1.1, screenheight * 1.1, false));
        textManager2.PrepareDraw();

        trace("width:" + screenwidth);
        trace("height:" + screenheight);
        //text renderer2
        alexisTextRenderer2 = new AlexisTextRenderer(textManager2, "font/font.png", 1.0, 1.0, 1.0);
        alexisTextRenderer2.initialize();
        alexisTextRenderer2.ui = true;
    }

    private function destroyMesh()
    {
        alexisBackground.destroyBuffers();
        alexisTextRenderer.destroyBuffers();
        alexisTextRenderer2.destroyBuffers();
    }

    private function update(deltaTime: Float, currentTime: Float)
    {
        // setup light
        ambientColor.data.offset = 0;
        lightColor.data.offset = 0;
        lightDirection.data.offset = 0;

        lightPosition.x = Math.sin(currentTime) * 2;
        lightPosition.y = Math.cos(currentTime) * 2;
        lightPosition.z = Math.sin(currentTime) + 1;

        lightDirection.set(lightPosition);

        modelMatrix.setIdentity();

        normalMatrix3.writeMatrix4IntoMatrix3(modelMatrix);
        normalMatrix3.inverse();

        viewMatrix.setLookAt(cameraPosition, zeroPosition, upDirection);

        modelMatrix.setTranslation(0.0, 0.0, 0.0);

        mvpObj.set(modelMatrix);
        mvpObj.multiply(viewMatrix);
        mvpObj.multiply(projection);

        //text matrix
        alexisTextRenderer.y += deltaTime * 0.3;
        modelMatrix.setTranslation(alexisTextRenderer.x, alexisTextRenderer.y, alexisTextRenderer.z);

        mvpText.set(modelMatrix);
        mvpText.multiply(viewMatrix);
        mvpText.multiply(projection);

        alexisTextRenderer.setMVP(mvpText);
        alexisTextRenderer2.setMVP(mvpObj);
    }

    override private function render()
    {
        update(DuellKit.instance().frameDelta, DuellKit.instance().time);

        GL.clear(GLDefines.COLOR_BUFFER_BIT | GLDefines.DEPTH_BUFFER_BIT);

        alexisBackground.draw();

        GL.bindTexture(GLDefines.TEXTURE_2D, GL.nullTexture);

        //text
        alexisTextRenderer.draw();
        alexisTextRenderer2.draw();

        GL.useProgram(GL.nullProgram);
    }
}
