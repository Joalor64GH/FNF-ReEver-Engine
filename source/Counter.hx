package;

import haxe.Timer;
import openfl.events.Event;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;

/**
 * FPS class extension to display memory usage.
 * @author Kirill Poletaev
 */
class Counter extends TextField
{
    private var times:Array<Float>;

    private var memPeak:Float = 0;

    public function new(inX:Float = 10.0, inY:Float = 10.0, inCol:Int = 0x000000) 
    {
        super();
        x = inX;
        y = inY;

        selectable = false;
        defaultTextFormat = new TextFormat("_sans", 12, inCol);
        text = "FPS: ";
        
        times = [];
        addEventListener(Event.ENTER_FRAME, onEnter);
        width = 150;
        height = 70;
    }

    private function onEnter(_)
    {   
        var now = Timer.stamp();
        times.push(now);

        while (times[0] < now - 1)
            times.shift();

        var mem:Float = System.totalMemory;
        var memUnit:String = "B";
        var memValue:Float = mem;

        if (mem >= 1024) {
            memValue = mem / 1024;
            memUnit = "KB";
        }

        if (memValue >= 1024) {
            memValue = memValue / 1024;
            memUnit = "MB";
        }
        
        if (memValue >= 1024) {
            memValue = memValue / 1024;
            memUnit = "GB";
        }

        memValue = Math.round(memValue * 100) / 100;

        if (memValue > memPeak) memPeak = memValue;

        if (visible)
        {   
            text = "FPS: " + times.length + "\nMEM: " + memValue + " " + memUnit + "\nMEM peak: " + memPeak + " " + memUnit;   
        }
    }
}