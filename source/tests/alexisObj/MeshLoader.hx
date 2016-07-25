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
import tests.utils.AssetLoader;

import filesystem.FileSystem;
import Std;
import StringTools;

class MeshLoader
{
    static private var pos: Int = 0;
    static private var vertices: Array<Vector3>;
    static private var vertexes: Array<Vector3>;
    static private var normals: Array<Vector3>;
    static private var faces: Array<Face>;

    static public function resetAttributes(): Void
    {
        pos = 0;
        vertices = null;
        vertexes = null;
        normals = null;
        faces = null;
    }

    static public function getTexturePath(path: String): String
    {
        var fileUrl = FileSystem.instance().getUrlToStaticData() + "/" + path;
        fileUrl = fileUrl.substr(0, fileUrl.length-3);

        //allowing a variety of formats
        var formats: Array<String> = ["tga","JPEG","PNG","png","JPG","jpg","pcx","bmp","dds"];
        var textureFound: Bool = false;
        for (i in 0...formats.length)
        {
            //trace("seek: " + fileUrl + formats[i]);
            if(FileSystem.instance().getFileReader(fileUrl + formats[i]) != null)
            {
                path = path.substr(0, path.length-3);
                fileUrl = path + formats[i];
                textureFound = true;
                break;
            }
        }

        if(!textureFound)
        {
            trace("Texture for " + path + " not found");
            return null;
        }

        trace("Texture " + fileUrl + " found");
        return fileUrl;
    }

    //different parsing functions
    static private function getNextWord(data: String): String
    {
        if(pos >= data.length)
            return null;

        var result: String = "";
        var nextChar: String = "";
        var currentPosLen: Int = 0;

        do
        {
            nextChar = data.substr(pos + currentPosLen, 1);
            currentPosLen += 1;
            result = data.substr(pos, currentPosLen);

            //trace(nextChar);
        }while(nextChar != " " && pos + currentPosLen<data.length);

        //v, vt, vn, f
        var specialWord: Bool = false;
        if(result.length>3)
        {
            /*
            v -0.240125 -0.821432 0.825275
            v -0.295974 -0.952863 0.801417
            v 0.211714 -0.813739 0.807320
            v -0.003266 -0.018714 1.293527
            */
            if(data.substr(pos + currentPosLen - 2,1) == "f" || data.substr(pos + currentPosLen - 2,1) == "v")
            {
                specialWord = true;
                result = data.substr(pos, currentPosLen - 2);
            }
            else if(data.substr(pos + currentPosLen - 3,2) == "vt" || data.substr(pos + currentPosLen - 3,2) == "vn")
            {
                specialWord = true;
                result = data.substr(pos, currentPosLen - 3);
            }
        }

        if(!specialWord)
        {
            //trace("!sw");
            if(nextChar == " ")
            {
                result = data.substr(pos, currentPosLen - 1);
                pos ++;
            }

        }
        else
        {
            //trace("sw");
        }

        pos += result.length;

        return result;
    }

    static private function isNumber(l: String): Bool
    {
        return (l.charCodeAt(0)>=48 && l.charCodeAt(0)<=57);
    }
    static private function getRidOfLetters(data: String): String
    {
        //at the end
        while(data.length>1 && !isNumber(data.substr(data.length-1,1)))
            data = data.substr(0,data.length-1);

        //at the front
        while(data.length>1 && !isNumber(data.substr(0,1)))
            data = data.substr(1,data.length);

        return data;
    }


    //actual parsing of a .obj file
    static public function load(fileName: String): Void
    {
        resetAttributes();
        trace("Start loading " + fileName);

        var data: String = AssetLoader.getStringFromFile(fileName);
        if(data == null)
        {
            trace("Error: File " + fileName + " not found!");
            return null;
        }

        //trace(data); //The output is too long, I dont want to always trace this
        trace("File found! Begin parsing...");

        vertices = new Array<Vector3>();
        vertexes = new Array<Vector3>();
        normals = new Array<Vector3>();
        faces = new Array<Face>();

        pos = 0;
        var currentWord: String = "";

        var count: Int = 0;

        while (pos < data.length && currentWord != null)
        {
            count++;
            //until there is a space, add letters to the current word
            currentWord = getNextWord(data);
            //we found a space so we can analyze our word
            if(currentWord == "v") //vertice
            {
                //trace("a v");
                currentWord = getNextWord(data);
                var x: Float = Std.parseFloat(currentWord);
                //trace("cw: " + currentWord);

                currentWord = getNextWord(data);
                var y: Float = Std.parseFloat(currentWord);
                //trace("cw: " + currentWord);

                currentWord = getNextWord(data);
                var z: Float = Std.parseFloat(currentWord);
                //trace("cw: " + currentWord);

                var vect3: Vector3 = new Vector3();
                vect3.setXYZ(x, y, z);

                vertices.push(vect3);
            }
            else if(currentWord == "vt") //vertex
            {
                //trace("a vt");
                currentWord = getNextWord(data);
                var x: Float = Std.parseFloat(currentWord);

                currentWord = getNextWord(data);
                var y: Float = Std.parseFloat(currentWord);

                var vect3: Vector3 = new Vector3();
                vect3.setXYZ(x, y, 0);

                vertexes.push(vect3);
            }
            else if(currentWord == "vn") //normal
            {
                //trace("a vn");
                currentWord = getNextWord(data);
                var x: Float = Std.parseFloat(currentWord);

                currentWord = getNextWord(data);
                var y: Float = Std.parseFloat(currentWord);

                currentWord = getNextWord(data);
                var z: Float = Std.parseFloat(currentWord);

                var vect3: Vector3 = new Vector3();
                vect3.setXYZ(x, y, z);

                normals.push(vect3);
            }
            else if(currentWord == "f")
            {
                //trace("f");
                var v1, v2, v3, vt1, vt2, vt3, vn1, vn2, vn3: Int = 0;

                currentWord = getNextWord(data);
                //trace("fcw: " + currentWord);

                var firstPart = currentWord.substr(0,currentWord.indexOf("/"));
                var secondPart = currentWord.substr(firstPart.length+1,currentWord.lastIndexOf("/"));
                var thirdPart = currentWord.substr(secondPart.length+1,currentWord.length);
                thirdPart = getRidOfLetters(thirdPart);

                v1 = Std.parseInt(firstPart);
                vt1 = Std.parseInt(secondPart);
                vn1 = Std.parseInt(thirdPart);

                currentWord = getNextWord(data);
                //trace("fcw: " + currentWord);

                firstPart = currentWord.substr(0,currentWord.indexOf("/"));
                secondPart = currentWord.substr(firstPart.length+1,currentWord.lastIndexOf("/"));
                thirdPart = currentWord.substr(secondPart.length+1,currentWord.length);
                thirdPart = getRidOfLetters(thirdPart);

                v2 = Std.parseInt(firstPart);
                vt2 = Std.parseInt(secondPart);
                vn2 = Std.parseInt(thirdPart);

                currentWord = getNextWord(data);
                //trace("fcw: " + currentWord);

                firstPart = currentWord.substr(0,currentWord.indexOf("/"));
                secondPart = currentWord.substr(firstPart.length+1,currentWord.lastIndexOf("/"));
                thirdPart = currentWord.substr(secondPart.length+1,currentWord.length);
                thirdPart = getRidOfLetters(thirdPart);

                v3 = Std.parseInt(firstPart);
                vt3 = Std.parseInt(secondPart);
                vn3 = Std.parseInt(thirdPart);

                if(!(v1-1>=0 && v1-1<vertices.length))
                    trace("Error face v1: " + v1 + "/" + vertices.length);
                else if(!(v2-1>=0 && v2-1<vertices.length))
                    trace("Error face v2: " + v2 + "/" + vertices.length);
                else if(!(v3-1>=0 && v3-1<vertices.length))
                    trace("Error face v3: " + v3 + "/" + vertices.length);
                else if(!(vt1-1>=0 && vt1-1<vertexes.length))
                    trace("Error face vt1: " + vt1 + "/" + vertexes.length);
                else if(!(vt2-1>=0 && vt2-1<vertexes.length))
                    trace("Error face vt2: " + vt2 + "/" + vertexes.length);
                else if(!(vt3-1>=0 && vt3-1<vertexes.length))
                    trace("Error face vt3: " + vt3 + "/" + vertexes.length);
                else if(!(vn1-1>=0 && vn1-1<normals.length))
                    trace("Error face vn1: " + vn1 + "/" + normals.length);
                else if(!(vn2-1>=0 && vn2-1<normals.length))
                    trace("Error face vn2: " + vn2 + "/" + normals.length);
                else if(!(vn3-1>=0 && vn3-1<normals.length))
                    trace("Error face vn3: " + vn3 + "/" + normals.length);
                else {
                    var face: Face = new Face(vertices[v1-1], vertices[v2-1], vertices[v3-1],
                                                vertexes[vt1-1], vertexes[vt2-1], vertexes[vt3-1],
                                                normals[vn1-1], normals[vn2-1], normals[vn3-1]);
                    faces.push(face);
                }

            }
        }
        trace("End parsing.");
        trace(count + " steps");
    }

    static public function getVertices(): Array<Vector3>
    {
        return vertices;
    }
    static public function getVertexes(): Array<Vector3>
    {
        return vertexes;
    }
    static public function getNormals(): Array<Vector3>
    {
        return normals;
    }
    static public function getFaces(): Array<Face>
    {
        return faces;
    }
}
