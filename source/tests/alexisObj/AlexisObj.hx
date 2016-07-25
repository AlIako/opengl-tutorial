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

import duellkit.DuellKit;
import gl.GL;
import gl.GLDefines;
import types.Data;
import types.Vector3;
import types.Matrix3;
import types.Matrix3Matrix4Tools;
import types.Matrix4;
import types.Matrix4Tools;
import tests.utils.AssetLoader;
import tests.utils.Shader;

using types.Matrix4Tools;
using types.Matrix3Tools;
using types.Matrix3Matrix4Tools;
using types.Matrix3DataTools;

class AlexisObj extends OpenGLTest
{
    inline static private var floatSize: Int = 4;
    inline static private var matrix3Size: Int = 9;

    private var alexisObjMesh: AlexisObjMesh;
    private var alexisObjMesh2: AlexisObjMesh;

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
    private var mvpObj2: Matrix4;

    private var palmPos: Vector3;
    private var palmLook: Vector3;

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
        GL.clearColor(0.0, 0.69, 0.66, 1.0);
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
        mvpObj2 = new Matrix4();

        palmPos = new Vector3();
        palmPos.setXYZ(0.0, 0.0, 0.5);
        palmLook = new Vector3();
        palmLook.setXYZ(0.0, -4.0, -7.5);
    }

    private function createMesh()
    {
        //Disable cull face to simplify our mesh rendering
        GL.disable(GLDefines.CULL_FACE);

        alexisObjMesh = new AlexisObjMesh();
        if(alexisObjMesh.loadMesh("mesh/palm.obj", 1))
            alexisObjMesh.createBuffers();

        alexisObjMesh2 = new AlexisObjMesh();
        if(alexisObjMesh2.loadMesh("mesh/slime.obj", .5))
            alexisObjMesh2.createBuffers();
    }

    private function destroyMesh()
    {
        alexisObjMesh.destroyBuffers();
        alexisObjMesh2.destroyBuffers();
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

        // setup MVP for alexis Mesh
        modelMatrix.setIdentity();

        normalMatrix3.writeMatrix4IntoMatrix3(modelMatrix);
        normalMatrix3.inverse();

        viewMatrix.setLookAt(cameraPosition, zeroPosition, upDirection);

        modelMatrix.setLookAt(palmPos, palmLook, upDirection);

        mvpObj.set(modelMatrix);
        mvpObj.multiply(viewMatrix);
        mvpObj.multiply(projection);

        //passing properties to alexis Mesh
        alexisObjMesh.setMVP(mvpObj); //MVP Matrix is important to the positioning in the shader

        // setup MVP for alexis Mesh2
        modelMatrix.setTranslation(1.0, .5, -0.5);

        mvpObj2.set(modelMatrix);
        mvpObj2.multiply(viewMatrix);
        mvpObj2.multiply(projection);

        //passing properties to alexis Mesh
        alexisObjMesh2.setMVP(mvpObj2); //MVP Matrix is important to the positioning in the shader

        normalMatrix3.writeMatrix3IntoData(normalMatrix3Data);
        alexisObjMesh.setLightVectors(normalMatrix3Data, ambientColor, lightColor, lightDirection, lightPosition);
        alexisObjMesh2.setLightVectors(normalMatrix3Data, ambientColor, lightColor, lightDirection, lightPosition);
    }

    override private function render()
    {
        update(DuellKit.instance().frameDelta, DuellKit.instance().time);

        GL.clear(GLDefines.COLOR_BUFFER_BIT | GLDefines.DEPTH_BUFFER_BIT);

        alexisObjMesh.draw();
        alexisObjMesh2.draw();

        GL.bindTexture(GLDefines.TEXTURE_2D, GL.nullTexture);

        GL.useProgram(GL.nullProgram);
    }
}
