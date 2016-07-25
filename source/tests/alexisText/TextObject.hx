
package tests.alexisText;

import types.Vector3;

class TextObject {

    public var text: String;
    public var x: Float;
    public var y: Float;
    public var color: Vector3;
    public var alignCenter: Bool;

    public function new(?txt: String, ?xcoord: Float, ?ycoord: Float, ?align: Bool)
    {
        text = (txt == null) ? "default" : txt;
        x = (xcoord == null) ? 0 : xcoord;
        y = (ycoord == null) ? 0 : ycoord;
        alignCenter = (align == null) ? false : align;

        color = new Vector3();
        color.setXYZ(1.0, 1.0, 1.0);
    }
}
