package options;

import openfl.Lib;

class Framerate {
    // hey, didnt know that fps can be float instead of int
    public static function change(fps:Float):Float
        return Lib.current.stage.frameRate = fps;
}