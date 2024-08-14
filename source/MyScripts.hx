package;

import sys.io.File;
import hscript.Expr;
import haxe.ds.StringMap;
import hscript.Parser;
import hscript.Interp;

using StringTools;

class MyScripts {
    public static var interp:Interp = new Interp();
    public static var parser:Parser = new Parser();

    public static var exp:StringMap<Dynamic> = new StringMap<Dynamic>();

    public function new(contents:Expr, ?extraParams:StringMap<Dynamic>) {
        for (i in exp.keys()) {
            interp.variables.set(i, exp.get(i));
        }

        if (extraParams != null) {
            for (i in extraParams.keys()) {
                interp.variables.set(i, extraParams.get(i));
            }
        }

        parser.allowTypes = true;
        interp.execute(contents);
    }

    public function setExp(vari:String, value:Dynamic)
        return exp.set(vari, value);

	public function exists(field:String):Bool
		return interp.variables.exists(field);

    public function get(field:String):Dynamic
		return interp.variables.get(field);

    public static function execute(module:String, ?extraParams:StringMap<Dynamic>) {
        return new MyScripts(parser.parseString(File.getContent(module)), extraParams);
    }
}